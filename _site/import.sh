ruby -rubygems -e 'require "jekyll-import";
    JekyllImport::Importers::WordpressDotCom.run({
       "no_fetch_images" => true,
       "source" => "bluecollarbioinformatics.wordpress.2015-09-13.xml",
     })'
