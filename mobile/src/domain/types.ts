export type TasteAxis = 'taste' | 'texture' | 'vibe' | 'for';

export type TasteTag = {
  code: string;
  axis: TasteAxis;
  labelEn: string;
  labelKo: string;
  emoji: string;
  sortOrder: number;
};

export type PlaceTaste = {
  tag: TasteTag;
  strength: number;
};

export type GooglePhotoAttribution = {
  displayName: string;
  uri: string | null;
  photoUri: string | null;
};

export type GooglePlacePhoto = {
  uri: string;
  googleMapsUri: string | null;
  attributions: GooglePhotoAttribution[];
};

export type PlaceProvider = 'pind' | 'google_places';

export type Place = {
  id: number;
  slug: string;
  provider: PlaceProvider;
  externalPlaceId: string | null;
  nameEn: string;
  nameKo: string;
  category: string;
  addressEn: string;
  addressKo: string;
  latitude: number;
  longitude: number;
  heroImageUrl: string | null;
  googleMapsUri: string | null;
  photoGoogleMapsUri: string | null;
  photoAttributions: GooglePhotoAttribution[];
  gallery: GooglePlacePhoto[];
  shortDescriptionEn: string;
  shortDescriptionKo: string;
  businessStatus: string | null;
  isOpenNow: boolean | null;
  weekdayDescriptions: string[];
  websiteUri: string | null;
  phoneNumber: string | null;
  editorialSummary: string | null;
  isDemo: boolean;
  tastes: PlaceTaste[];
};

export type GooglePlaceCandidate = {
  externalPlaceId: string;
  name: string;
  category: string;
  address: string;
  latitude: number;
  longitude: number;
  heroImageUrl: string | null;
  googleMapsUri: string;
  photoGoogleMapsUri: string | null;
  photoAttributions: GooglePhotoAttribution[];
  gallery: GooglePlacePhoto[];
  businessStatus?: string | null;
  isOpenNow?: boolean | null;
  weekdayDescriptions?: string[];
  websiteUri?: string | null;
  phoneNumber?: string | null;
  editorialSummary?: string | null;
};

export type MatchResult = {
  score: number;
  reasons: TasteTag[];
};

export type PindPost = {
  id: number;
  authorId: string;
  placeId: number;
  menuName: string;
  photoPath: string;
  photoUrl: string;
  emoji: string;
  body: string;
  isPublic: boolean;
  tasteTagCodes: string[];
  createdAt: string;
  updatedAt: string;
};

export type MapLogSource = 'mine' | 'friend' | 'default';

export type MapLog = {
  id: string;
  source: MapLogSource;
  placeId: number;
  authorName: string;
  menuName: string;
  photoUrl: string;
  emoji: string;
  body: string;
  tasteTagCodes: string[];
  createdAt: string;
  post?: PindPost;
};
