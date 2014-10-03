module Xcodeci
  class HtmlReporter
    def initialize db_path, drobox_userid
      @db_path = db_path
      @user_id  = drobox_userid
    end

    def table_cell_for_boolean value
      klass = value ? 'positive' : 'negative'
      text = value ? "✔︎" : "✘"
      "<td class=\"#{klass}\";>#{text}</td>"
    end

    def manifest_link appname, commit
      "https://dl.dropboxusercontent.com/u/#{@user_id}/xcodeci/#{appname}/#{commit}/manifest.plist"
    end
    def ipa_link appname, commit
      "https://dl.dropboxusercontent.com/u/#{@user_id}/xcodeci/#{appname}/#{commit}/app.ipa"
    end
    def itunes_link appname, commit
      "itms-services://?action=download-manifest&url=#{manifest_link appname, commit}"
    end

    def html_report
      database = YAML.load_file(@db_path)
      html_row = ""

      database.each do |project, commits|
        html_row << %[
        <h1>#{project}</h1>
          <table id="newspaper-a">
            <thead>
              <tr>
                <th scope="col">Date</th>
                <th scope="col">Commit</th>
                <th scope="col">Email</th>
                <th scope="col">Build</th>
                <th scope="col">Test</th>
                <th scope="col">IPA</th>
                <th scope="col">dSym</th>
                <th scople="col">Manifest</th>
                <th scople="col">IPA</th>
                <th scople="col">Install</th>
              </tr>
            </thead>
          <tbody>
        ]
        sorted_commits = commits.keys.sort {|c1, c2| 
            commits[c1][:date] <=> commits[c2][:date]
        }
        sorted_commits.each do | commit |
          report = commits[commit]
          html_row << "<tr><td width=\"50px\">#{report[:date].strftime('%D')}</td>" \
            "<td width=\"50px\">#{commit}</td>"                         \
            "<td>#{report[:author]}</td>"                         \
            "#{table_cell_for_boolean report[:build]}" \
            "#{table_cell_for_boolean report[:test]}"  \
            "#{table_cell_for_boolean report[:ipa]}"   \
            "#{table_cell_for_boolean report[:dSym]}"  \
            "<td><a href=\"#{URI::encode(manifest_link project, commit)}\">Manifest</a></td>"  \
            "<td><a href=\"#{URI::encode(ipa_link project, commit)}\">IPA</a></td>"  \
            "<td><a href=\"#{URI::encode(itunes_link project, commit)}\">Install</a></td>"  \
            "</tr>"
        end #end loop commits
        html_row << "
          </tbody>
          </table>
        "
      end # <- End loo projects

      html_template_path =  File.join(Xcodeci::TEMPLATE, 'index.html')
      html_template = File.open(html_template_path, 'rb') { |f| f.read }
      html_template.gsub!('<!-- __TABLE_PLACEHOLDER__ -->', html_row)
      html_template
    end
    
  end
end