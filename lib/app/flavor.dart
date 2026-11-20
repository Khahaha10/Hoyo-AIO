enum Flavor {
  dev(appTitle: 'HoYo Dev', verboseLogging: true, galleryEnabled: true),
  prod(appTitle: 'HoYo AIO', verboseLogging: false, galleryEnabled: false);

  const Flavor({
    required this.appTitle,
    required this.verboseLogging,
    required this.galleryEnabled,
  });

  final String appTitle;
  final bool verboseLogging;
  final bool galleryEnabled;
}
