import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

/** Payload accepted when creating an example. Validated at the boundary (A3). */
export class CreateExampleDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name!: string;
}
