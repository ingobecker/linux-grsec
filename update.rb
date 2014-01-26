#!/usr/bin/env ruby

require 'open-uri'

begin
  require 'nokogiri'
rescue LoadError
  $stderr << "Install nokogiri (gem install nokogiri).\n"
  exit 1
end

class Pkgbuild
  attr_reader :version, :timestamp

  def initialize
    @version, @timestamp = versions
  end

  def major
    @major ||= version.split('.')[0..1].join('.')
  end

  def update!(patch)
    c = File.open('PKGBUILD').readlines

    c.each_with_index do |line, i|
      if line =~ /^_basekernel=/
        c[i] = "_basekernel=#{major}\n"
      end

      if line =~ /^pkgver=/
        c[i] = "pkgver=${_basekernel}.#{version.split('.').last}\n"
      end

      if line =~ /^_timestamp=/
        c[i] = "_timestamp=#{timestamp}\n"
      end

      if line =~ /^pkgrel=/
        new = line.split('=').last.to_i + 1
        c[i] = "pkgrel=#{new}\n"
      end
    end

    File.open('PKGBUILD', 'w').write c.join
  end

  private

  def versions
    v, t = `bash PKGBUILD -v`.split ' '
    [v, t.to_i]
  end
end

class Patch
  URI = 'http://grsecurity.net/download.php'

  attr_reader :version, :timestamp

  def initialize
    @version, @timestamp = versions
  end

  def filename
    unless @filename
      doc = Nokogiri::HTML open URI
      patches = doc.css('div.left a').map &:content
      v = newest patches
      @filename = patches.select { |x| x.include? v }.first
    end

    @filename
  end

  private

  def newest(patches)
    select_version patches, :last
  end

  def select_version(patches, method)
    a = patches.sort.map { |x| x.split('-')[2] }
    a.select! { |x| x =~ /^[0-9]{1}\./ }
    a.map! { |x| Gem::Version.new x rescue nil }
    a.sort.send(method).to_s
  end

  def versions
    v, t = filename.split('-')[2..3]
    t = t.split('.').first
    [v, t.to_i]
  end
end

pkgbuild = Pkgbuild.new
patch = Patch.new

if pkgbuild.timestamp < patch.timestamp
  pkgbuild.update! patch
  puts `git diff`
else
  puts 'PKGBUILD is up-to-date.'
end
