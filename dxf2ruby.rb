require 'pp'

module Igicom
  module Dxf2Ruby
    HEADER = "HEADER"
    SECTION = "SECTION"
    EOF = "EOF"
    BLOCKS = "BLOCKS"
    ENTITIES = "ENTITIES"
    ENDSEC = "ENDSEC"
    LWPOLYLINE = "LWPOLYLINE"
    TABLES = "TABLES"
    CLASSES = "CLASSES"
    def self.parse(filename)
      fp = File.open(filename, 'r')
      dxf = {HEADER => {}, BLOCKS => [], ENTITIES => []}
      # pp dxf

      #
      # main loop
      #

      while true
        c, v = read_codes(fp)
        break if v == EOF
        if v == SECTION
          c, v = read_codes(fp)
          case v
          when HEADER
            hdr = dxf[HEADER]
            while true
              c, v = read_codes(fp)
              break if v == ENDSEC # or v == BLOCKS or v == ENTITIES or v == EOF
              if c == 9
                key = v
                dxf[HEADER][key] = {}
              else
                add_att(dxf[HEADER][key], c, v)
              end
            end # while

          when BLOCKS
            blks = dxf[BLOCKS]
            parse_entities(blks, fp)

          when ENTITIES
            ents = dxf[ENTITIES]
            parse_entities(ents, fp)
          else
            puts "UNSUPPORTED SECTION: #{v}"
          end
        end # if in SECTION

      end # main loop
      # pp dxf
      fp.close
      return dxf
    end

    def self.parse_entities(section, fp)
      last_ent = nil
      last_code = nil
      while true
        c, v = read_codes(fp)
        break if v == ENDSEC or v == EOF
        next if c == 999
        # LWPOLYLINE seems to break the rule that we can ignore the order of codes.
        if last_ent == LWPOLYLINE
          if c == 10
            section[-1][42] ||= []
            # Create default 42
            add_att(section[-1], 42, 0.0)
          end
          if c == 42
            # update default
            section[-1][42][-1] = v
            next
          end
        end
        if c == 0
          last_ent = v
          section << {c => v}
        else
          add_att(section[-1], c, v)
        end
        last_code = c
      end # while
    end # def self.parse_entities

    def self.read_codes(fp)
      c = fp.gets
      return [0, EOF] if c.nil?
      v = fp.gets
      return [0, EOF] if v.nil?
      c = c.to_i
      v.strip!
      v.upcase! if c == 0
      case c
      when 10..59, 140..147, 210..239, 1010..1059
        v = v.to_f
      when 60..79, 90..99, 170..175,280..289, 370..379, 380..389,500..409, 1060..1079
        v = v.to_i
      end
      # puts "Read code [#{c}, #{v}]"
      return( [c, v] )
    end

    def self.add_att(ent, code, value)
      # Initially, I thought each code mapped to a single value. Turns out
      # a code can be a list of values.
      if ent.nil? and $JFDEBUG
        p caller
        p code
        p value
      end
      if ent[code].nil?
        ent[code] = value
      elsif ent[code].class == Array
        ent[code] << value
      else
        t = ent[code]
        ent[code] = []
        ent[code] << t
        ent[code] << value
      end
    end


  end # mod Dxf2Ruby
end # mod JF


if $0 == __FILE__
  t1 = Time.now
  pretty = ARGV.delete('-p')
  filename = ARGV.shift
  puts "Ruby Version: #{RUBY_VERSION}"
  puts "File: #{File.expand_path(filename)}"
  dxf = Dxf2Ruby.parse(filename)
  puts "Finished in #{Time.now - t1}"
  if pretty
    require 'pp'
    s = PP.pp(dxf, "")
  else
    s = ""
    dxf.each do |sec, list|
      s << sec.to_s << "\n"
      list.each { |line| s << line.to_s << "\n" }
    end
  end
  cmd = "less -S"
  IO.popen(cmd, 'w') { |f| f.puts(s) }
end
