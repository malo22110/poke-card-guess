import { Injectable } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async validateOAuthLogin(profile: any, provider: string): Promise<any> {
    const user = await this.usersService.findOrCreate(profile, provider);
    const payload = { sub: user.id, email: user.email, name: user.name };

    return {
      access_token: this.jwtService.sign(payload),
      user,
    };
  }
}
