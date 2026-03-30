import {
  Controller,
  Get,
  Patch,
  Post,
  Body,
  UseGuards,
  Request,
  NotFoundException,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import sharp from 'sharp';
import * as fs from 'fs';
import * as path from 'path';
import { UsersService } from './users.service';
import { TrophiesService } from '../trophies/trophies.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '@prisma/client';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly trophiesService: TrophiesService,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req): Promise<User> {
    const userId = req.user.userId as string;
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  async updateProfile(
    @Request() req,
    @Body()
    body: { name?: string; picture?: string; socials?: Record<string, string> },
  ): Promise<User> {
    const userId = req.user.userId as string;

    const updateData: Record<string, unknown> = {
      name: body.name,
      picture: body.picture,
      profileCompleted: true,
    };

    if (body.socials) {
      updateData.socials = JSON.stringify(body.socials);
    }

    return this.usersService.update(userId, updateData);
  }

  @UseGuards(JwtAuthGuard)
  @Post('profile-picture')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
      fileFilter: (_req, file, cb) => {
        const isValidMime = file.mimetype.match(
          /image\/(jpg|jpeg|png|webp|gif)/,
        );
        // Flutter Web sometimes sends 'application/octet-stream' – validate by extension in that case
        const isValidExt = file.originalname.match(
          /\.(jpg|jpeg|png|webp|gif)$/i,
        );
        if (!isValidMime && !isValidExt) {
          cb(new BadRequestException('Only image files are allowed'), false);
        } else {
          cb(null, true);
        }
      },
    }),
  )
  async uploadProfilePicture(
    @Request() req,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<{ pictureUrl: string; user: User }> {
    if (!file || !file.buffer || file.buffer.length < 4) {
      throw new BadRequestException('No file provided');
    }

    // === SECURITY: Magic bytes (file signature) validation ===
    // This prevents a malicious actor from renaming an executable/.zip/etc. to .jpg
    // We check the raw first bytes of the buffer — these cannot be faked by just changing the extension.
    const magic = file.buffer;
    const isJpeg = magic[0] === 0xff && magic[1] === 0xd8 && magic[2] === 0xff;
    const isPng =
      magic[0] === 0x89 &&
      magic[1] === 0x50 &&
      magic[2] === 0x4e &&
      magic[3] === 0x47;
    const isGif = magic[0] === 0x47 && magic[1] === 0x49 && magic[2] === 0x46;
    const isWebp =
      magic[0] === 0x52 &&
      magic[1] === 0x49 &&
      magic[2] === 0x46 &&
      magic[3] === 0x46;
    if (!isJpeg && !isPng && !isGif && !isWebp) {
      throw new BadRequestException(
        'Invalid image file. File content does not match a supported image format.',
      );
    }

    const userId = req.user.userId as string;

    // Ensure uploads/avatars directory exists
    const uploadDir = path.resolve(process.cwd(), 'uploads', 'avatars');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    // === SECURITY: Path traversal protection when deleting old avatar ===
    // We resolve the old file path and ensure it is inside the allowed uploadDir before deleting.
    const existingUser = await this.usersService.findById(userId);
    if (existingUser?.picture?.startsWith('/uploads/avatars/')) {
      const oldFilePath = path.resolve(
        process.cwd(),
        existingUser.picture.replace(/^\//, ''),
      );
      // Confirm the resolved path is actually inside our uploads directory
      if (oldFilePath.startsWith(uploadDir) && fs.existsSync(oldFilePath)) {
        fs.unlinkSync(oldFilePath);
      }
    }

    // Resize, crop to square, and convert to webp
    const filename = `${userId}-${Date.now()}.webp`;
    const outputPath = path.join(uploadDir, filename);

    // === SECURITY: sharp is used as a final sanitization layer ===
    // Even if a corrupted or polyglot image sneaks past the magic bytes check,
    // sharp will parse and re-encode the pixel data into a clean WebP output,
    // stripping any embedded scripts, metadata, or payloads in the process.
    // We wrap in try/catch so we never leak internal sharp error details to the client.
    try {
      await sharp(file.buffer)
        .resize(256, 256, { fit: 'cover', position: 'center' })
        .webp({ quality: 80 })
        .toFile(outputPath);
    } catch {
      throw new BadRequestException(
        'Could not process the image. Please try a different file.',
      );
    }

    const pictureUrl = `/uploads/avatars/${filename}`;

    const user = await this.usersService.update(userId, {
      picture: pictureUrl,
      profileCompleted: true,
    });

    return { pictureUrl, user };
  }

  @UseGuards(JwtAuthGuard)
  @Post('share')
  async trackShare(@Request() req): Promise<{
    success: boolean;
    totalShares: number;
    newTrophies?: unknown[];
  }> {
    const userId = req.user.userId as string;
    const user = await this.usersService.incrementShareCount(userId);

    const newTrophies = await this.trophiesService.checkAndAwardTrophies(
      userId,
      { category: 'social' },
    );

    return {
      success: true,
      totalShares: user.sharesCount,
      newTrophies,
    };
  }

  @Post('donation')
  async recordDonation(
    @Request() req,
    @Body() body: { amount: number },
  ): Promise<{
    success: boolean;
    totalDonated: number;
    newTrophies: unknown[];
  }> {
    const userId = req.user.userId as string;
    const amountInCents = Math.round(body.amount * 100);
    const user = await this.usersService.addDonation(userId, amountInCents);

    const newTrophies = await this.trophiesService.checkAndAwardTrophies(
      userId,
      { category: 'donation' },
    );

    return {
      success: true,
      totalDonated: user.totalDonated / 100,
      newTrophies,
    };
  }
}
