#
# Be sure to run `pod spec lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about the attributes see http://docs.cocoapods.org/specification.html
#
Pod::Spec.new do |s|
  s.name         = "SEBannerViewController"
  s.version      = "0.0.1"
  s.summary      = "A drop-in iAd & AdMob Banner View Controller."
  # s.description  = <<-DESC
  #                   An optional longer description of SEBannerViewController

  #                   * Markdown format.
  #                   * Don't worry about the indent, we strip it!
  #                  DESC
  s.homepage     = "https://github/segiddins/SEBannerViewController"
  s.screenshots  = "https://raw.github/segiddins/SEBannerViewController/Screenshots/screenshot~iphone.png", "https://raw.github/segiddins/SEBannerViewController/Screenshots/screenshot~ipad.png"
  s.license      = 'BSD'
  s.author       = { "Samuel E. Giddins" => "segiddins@segiddins.me" }
  s.source       = { :git => "https://github/segiddins/SEBannerViewController/", :tag => "v#{s.version}" }

  s.platform     = :ios, '5.0'
  s.requires_arc = true

  s.source_files = 'Classes/**/*.{h,m}'
  s.resources = 'Assets'

  s.ios.exclude_files = 'Classes/osx'
  s.public_header_files = 'Classes/**/*.h'
  s.frameworks = 'iAd'

end
