-- Keep an already corrected English address when an older SBIZ batch is
-- re-imported with address_ko copied into address_en. A future import that
-- supplies a real English address can still replace the old Korean fallback.
do $$
declare
  function_definition text;
begin
  function_definition := pg_get_functiondef(
    'public.import_sbiz_places(jsonb,date)'::regprocedure
  );

  if function_definition ~ 'address_en\s*=\s*excluded\.address_en' then
    function_definition := regexp_replace(
      function_definition,
      'address_en\s*=\s*excluded\.address_en',
      'address_en = CASE WHEN excluded.address_en = excluded.address_ko THEN public.places.address_en ELSE excluded.address_en END'
    );
    execute function_definition;
  elsif function_definition !~ 'CASE WHEN excluded\.address_en = excluded\.address_ko THEN public\.places\.address_en' then
    raise exception 'Could not find the expected address_en upsert in import_sbiz_places';
  end if;
end;
$$;
