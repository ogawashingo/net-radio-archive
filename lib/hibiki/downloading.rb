require 'shellwords'
require 'fileutils'

module Hibiki
  class Downloading
    def download(program)
      unless exec_rec(program)
        return false
      end
      exec_convert(program)
    end

    def exec_rec(program)
      filename = program.title
        .gsub(/\s/, '_')
        .gsub(/\//, '_')
      flv_path = filepath(program, 'flv')
      command = "rtmpdump -q -r #{Shellwords.escape(program.rtmp_url)} -o #{Shellwords.escape(flv_path)}"

      FileUtils.mkdir_p(hibiki_dir)
      exit_status, output = shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "rec failed. program:#{program}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def exec_convert(program)
      flv_path = filepath(program, 'flv')
      aac_path = filepath(program, 'aac')
      command = "avconv -y -i #{Shellwords.escape(flv_path)} -acodec copy #{Shellwords.escape(aac_path)}"
      exit_status, output = shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "convert failed. program:#{program}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def filepath(program, ext)
      date = Time.now.strftime('%Y_%m_%d')
      title_safe = "#{program.title}_#{program.comment}"
        .gsub(/\s/, '_')
        .gsub(/\//, '_')
      "#{hibiki_dir}/#{date}_#{title_safe}.#{ext}"
    end

    def shell_exec(command)
      output = `#{command}`
      exit_status = $?
      [exit_status, output]
    end

    def hibiki_dir
      "#{ENV['NET_RADIO_ARCHIVE_DIR']}/hibiki"
    end
  end
end
