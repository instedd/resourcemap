class ImportWizard
  TmpDir = "#{Rails.root}/tmp/import_wizard"

  class << self
    def import(user, collection, file)
      contents = file.read
      FileUtils.mkdir_p TmpDir
      File.open(file_for(user, collection), "wb") { |file| file << contents }

      # Just to validate its contents
      csv = CSV.new contents
      csv.each { |row| }
    end

    def sample(user, collection)
      rows = []
      i = 0
      CSV.foreach(file_for user, collection) do |row|
        rows << row
        i += 1
        break if i == 26
      end
      to_columns rows
    end

    private

    def to_columns(rows)
      columns = rows[0].select(&:present?).map{|x| {:name => x, :sample => "", :kind => :text, :code => x.downcase.gsub(/\s+/, ''), :label => x.titleize}}
      columns.each_with_index do |column, i|
        rows[1 .. 4].each do |row|
          if row[i]
            column[:value] = row[i].to_s unless column[:value]
            column[:sample] << ", " if column[:sample].present?
            column[:sample] << row[i].to_s
          end
        end
        column[:kind] = guess_column_kind(column, rows, i)
      end
    end

    def guess_column_kind(column, rows, i)
      return :lat if column[:name] =~ /^\s*lat/i
      return :lng if column[:name] =~ /^\s*(lon|lng)/i

      found = false

      rows[1 .. -1].each do |row|
        next if row[i].blank?

        found = true

        return :text if row[i].start_with?('0')
        Float(row[i]) rescue return :text
      end

      found ? :numeric : :ignore
    end

    def file_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}.csv"
    end
  end
end
