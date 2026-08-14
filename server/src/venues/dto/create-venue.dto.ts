/**
 * A class, not an interface: on step 5 ValidationPipe will read decorator
 * metadata off this type at runtime, and interfaces do not survive compilation.
 */
export class CreateVenueDto {
  name: string;
  address: string;
  city: string;
  capacity: number;
}
