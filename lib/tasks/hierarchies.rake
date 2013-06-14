namespace :csv do
  desc "Takes hierarchy CSV with duplicate names and generates an equivalent hierarchy CSV without name duplicates"
  task :remove_duplicates_from_hierarchy, [:path_to_csv, :output_file] => :environment do |t, args|
    def is_duplicate(row, matrix)
      matrix.select{|r| r[2] == row[2]}.length > 1
    end

    def append_parent_name(row, matrix)
      parent = matrix.select{|r| r[0] == row[1]}.first
      "#{row[2]} (#{parent[2]})"
    end

    p "Parsing input file..."
    csv = CSV.read(args[:path_to_csv])

    # Remove empty rows at the end
    while (last = csv.last) && last.empty?
      csv.pop
    end

    actual_rows = csv[1..-1]

    duplicate_rows = actual_rows.select {|r| is_duplicate(r, actual_rows) }

    corrected_rows = actual_rows.map do |r|
      name = r[2]

      if is_duplicate(r, actual_rows)
        name = append_parent_name r, actual_rows
      end

      [r[0], r[1], name]
    end

    corrected_rows_with_header = corrected_rows.unshift ['ID','ParentID','ItemName']

    p "Writing output CSV file..."
    CSV.open(args[:output_file], 'w') do |csv|
      corrected_rows_with_header.each do |r|
        csv << r
      end
    end

    p "Done, corrected #{duplicate_rows.length} duplicate names."
  end
end

