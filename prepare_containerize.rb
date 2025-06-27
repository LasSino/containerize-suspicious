# frozen_string_literal: true

MAPPED_FOLDER_TEMPLATE = File.open('./mapped_folder.xml.tmpl', 'rt', &:read)
SANDBOX_TEMPLATE = File.open('./Containerize.wsb.tmpl', 'rt', &:read)
MAPPING_FILE_DIRECTORY = './directory_mappings/'
FINAL_SANDBOX_FILE = 'Containerize.wsb'

require 'fileutils'

def ensure_folder(path = '')
  abs_path = File.expand_path(path, './')
  FileUtils.mkdir_p(abs_path)
  abs_path.tr('/', '\\')
end

def process_entry(sandbox, host, ro)
  abs_path = ensure_folder(host)
  mapping_xml = MAPPED_FOLDER_TEMPLATE.gsub('{{sandbox}}', sandbox)
  mapping_xml.gsub!('{{host}}', abs_path)
  mapping_xml.gsub!('{{ro}}', ro ? 'True' : 'False')
  mapping_xml
end

require 'yaml'

$sandbox_set = Set.new

def process_mapping_file(filename)
  mapping_list = []
  mapping_obj = YAML.load_file(filename)
  mapping_obj.each do |entry|
    if $sandbox_set.include?(entry['sandbox'])
      warn "Warning: Duplicate sandbox path skipped: #{entry['sandbox']} in file #{filename}"
      next
    end
    $sandbox_set << entry['sandbox']
    mapping_list << process_entry(entry['sandbox'], entry['host'], entry['ro'])
  end
  mapping_list
end

final_mapping_list = []

Dir.each_child(MAPPING_FILE_DIRECTORY) do |fn|
  full_fn = MAPPING_FILE_DIRECTORY + fn
  final_mapping_list += process_mapping_file(full_fn) if File.file?(full_fn)
end

mapping_folder_xml = final_mapping_list.join("\n")
final_xml = SANDBOX_TEMPLATE.gsub('{{OtherMappedFolders}}', mapping_folder_xml)
File.open(FINAL_SANDBOX_FILE, 'wt') { |f| f.write(final_xml) }

