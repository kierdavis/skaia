self: super: {
  librdf_redland = super.librdf_redland.override { withPostgresql = true; };
}
