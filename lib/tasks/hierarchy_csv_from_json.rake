
namespace :csv do
  desc "Generate a CSV to upload a hierarchy from its JSON representation"
  task :hierarchy_from_json, [:path_to_json, :output_file] => :environment do |t, args|
    def csv_header
      ['ID','ParentID','ItemName']
    end

    def csv_line(item, parent="")
      ["#{item['id']}", "#{parent}", "#{item['name']}"]
    end

    def csv_children(item, csv_stream)
      return unless item['sub']

      item['sub'].each do |child|
        csv_stream << csv_line(child, item['id'])
        csv_children child, csv_stream
      end
    end

    p "Parsing input file..."
    j = JSON.parse(IO.read(args[:path_to_json]))

    p "Writing CSV file..."
    CSV.open(args[:output_file], 'w') do |csv|
      csv << csv_header

      j.each do |top_level_item|
        csv << csv_line(top_level_item)
        csv_children top_level_item, csv
      end
    end
  end
end

