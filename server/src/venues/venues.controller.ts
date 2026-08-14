import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { VenuesService } from './venues.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { Venue } from './entities/venue.entity';

@Controller('venues')
export class VenuesController {
  constructor(private readonly venuesService: VenuesService) {}

  // Nest answers 201 for POST by default, which is what a created resource
  // should return.
  @Post()
  create(@Body() createVenueDto: CreateVenueDto): Promise<Venue> {
    return this.venuesService.create(createVenueDto);
  }

  @Get()
  findAll(): Promise<Venue[]> {
    return this.venuesService.findAll();
  }

  // ParseIntPipe turns a non-numeric id into a clean 400 before the service is
  // ever reached; without it the garbage would travel into SQL and surface as
  // a 500.
  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number): Promise<Venue> {
    return this.venuesService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateVenueDto: UpdateVenueDto,
  ): Promise<Venue> {
    return this.venuesService.update(id, updateVenueDto);
  }

  // Nest would answer 200 with an empty body here, but a successful delete has
  // nothing to say — 204 does.
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.venuesService.remove(id);
  }
}
