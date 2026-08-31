import { supabase } from '../lib/supabase';
import type { Place, TasteAxis, TasteTag } from '../domain/types';

type TasteTagRow = {
  code: string;
  axis: TasteAxis;
  label_en: string;
  label_ko: string;
  emoji: string;
  sort_order: number;
};

type PlaceRow = {
  id: number;
  slug: string;
  external_provider: string;
  external_place_id: string | null;
  name_en: string;
  name_ko: string;
  category: string;
  address_en: string;
  address_ko: string;
  latitude: number;
  longitude: number;
  hero_image_url: string;
  short_description_en: string;
  short_description_ko: string;
  is_demo: boolean;
};

type PlaceTasteRow = {
  place_id: number;
  taste_tag_code: string;
  strength: number;
};

export type DiscoveryData = {
  tags: TasteTag[];
  places: Place[];
};

export async function fetchDiscoveryData(): Promise<DiscoveryData> {
  const [tagsResult, placesResult, linksResult] = await Promise.all([
    supabase.from('taste_tags').select('code,axis,label_en,label_ko,emoji,sort_order').order('axis').order('sort_order'),
    supabase
      .from('places')
      .select('id,slug,external_provider,external_place_id,name_en,name_ko,category,address_en,address_ko,latitude,longitude,hero_image_url,short_description_en,short_description_ko,is_demo')
      .eq('is_reference_only', false)
      .order('name_en'),
    supabase.from('place_taste_tags').select('place_id,taste_tag_code,strength'),
  ]);

  const error = tagsResult.error ?? placesResult.error ?? linksResult.error;
  if (error) {
    throw new Error(error.message);
  }

  const tags = ((tagsResult.data ?? []) as TasteTagRow[]).map(mapTasteTag);
  const tagsByCode = new Map(tags.map((tag) => [tag.code, tag]));
  const links = (linksResult.data ?? []) as PlaceTasteRow[];

  const places = ((placesResult.data ?? []) as PlaceRow[]).map((row) => ({
    id: row.id,
    slug: row.slug,
    provider: 'pind' as const,
    externalPlaceId: row.external_place_id,
    nameEn: row.name_en,
    nameKo: row.name_ko,
    category: row.category,
    addressEn: row.address_en,
    addressKo: row.address_ko,
    latitude: row.latitude,
    longitude: row.longitude,
    heroImageUrl: row.hero_image_url,
    googleMapsUri: null,
    photoGoogleMapsUri: null,
    photoAttributions: [],
    gallery: [],
    shortDescriptionEn: row.short_description_en,
    shortDescriptionKo: row.short_description_ko,
    businessStatus: null,
    isOpenNow: null,
    weekdayDescriptions: [],
    websiteUri: null,
    phoneNumber: null,
    editorialSummary: null,
    isDemo: row.is_demo,
    tastes: links
      .filter((link) => link.place_id === row.id)
      .flatMap((link) => {
        const tag = tagsByCode.get(link.taste_tag_code);
        return tag ? [{ tag, strength: link.strength }] : [];
      }),
  }));

  return { tags, places };
}

function mapTasteTag(row: TasteTagRow): TasteTag {
  return {
    code: row.code,
    axis: row.axis,
    labelEn: row.label_en,
    labelKo: row.label_ko,
    emoji: row.emoji,
    sortOrder: row.sort_order,
  };
}
