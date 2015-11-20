Pod::Spec.new do |s|
  s.name             = "RZTouchID"
  s.version          = "1.1.2"
  s.summary          = "A simple API for using TouchID to store and retrieve passwords from the keychain."
  s.description      = <<-DESC
                       Provides an interface to add/remove passwords in the keychain, and retrieve them using TouchID. Provides support for passcode and password fallback options.
                       DESC
  s.homepage         = "https://github.com/Raizlabs/RZTouchID"
  s.license          = 'MIT'
  s.author           = { "Adam Howitt" => "adam.howitt@raizlabs.com" }
  s.social_media_url = 'https://twitter.com/raizlabs'
  s.source           = { :git => "https://github.com/Raizlabs/RZTouchID.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'RZTouchID'
  s.frameworks = 'UIKit','LocalAuthentication'
end
