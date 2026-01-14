import { Controller, Get, Req, Res, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Controller('auth')
export class AuthController {
  @Get('google')
  @UseGuards(AuthGuard('google'))
  googleAuth() {
    // Initiates the Google OAuth flow
  }

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  googleAuthRedirect(@Req() req, @Res() res) {
    const token = req.user.access_token;
    // Redirect to the frontend with the token
    // Adjust the URL to match your Flutter app's URL
    res.redirect(`http://localhost:8080/#/auth_callback?token=${token}`);
  }

  @Get('facebook')
  @UseGuards(AuthGuard('facebook'))
  facebookAuth() {}

  @Get('facebook/callback')
  @UseGuards(AuthGuard('facebook'))
  facebookAuthRedirect(@Req() req, @Res() res) {
    const token = req.user.access_token;
    res.redirect(`http://localhost:8080/#/auth_callback?token=${token}`);
  }
}
