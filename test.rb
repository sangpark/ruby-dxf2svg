require_relative 'dxf2ruby'
require 'pp'

SVG_PREAMBLE = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" viewBox=\"%{minX} %{minY} %{maxX} %{maxY}\">\n"
SVG_CLOSE = "</svg>\n"
def save_to_svg(dxf, outfile)
  # pp dxf
  header = dxf[Igicom::Dxf2Ruby::HEADER]
  minX = header['$EXTMIN'][10]
  minY = header['$EXTMIN'][20]
  maxX = header['$EXTMAX'][10]
  maxY = header['$EXTMAX'][20]
  puts "Setting header #{minX} #{minY} #{maxX} #{maxY}"
  outfile.write(SVG_PREAMBLE % { minX: minX, minY: minY, maxX: maxX, maxY: maxY })
  entities = dxf[Igicom::Dxf2Ruby::ENTITIES]
  unless entities.nil?
    for entity in entities do
      pp entity
    end
  end
  outfile.write(SVG_CLOSE)
end

filename = "test.dxf"
extension = File.extname(filename)
outfile = File.open(File.basename(filename, extension) + ".svg", 'w')
if File.file?(outfile)
  puts "The output file already exists"
end
dxf = Igicom::Dxf2Ruby.parse(filename)
header = dxf['HEADER']
acad_version = header['$ACADVER'][1] # ==> "AC1015"
# puts dxf.inspect

save_to_svg(dxf, outfile)
outfile.close

exec('/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --kiosk test.svg')
