# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file
require 'csv'

class ContributorsController < ApplicationController

  def show
    @contributor = Contributor.find(params[:id])
  end

  def contributions
    @contributor = Contributor.find(params[:id])

    if(!params[:download].nil? and params[:download] == 'csv')
    	@contributions = @contributor.contributions_by_node
      send_data(contributions_csv(@contributions),
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=contributions_for_#{@contributor.fullname.gsub(' ','_')}.csv")
    else
    	@contributions = @contributor.contributions_by_node.page(params[:page])
    end
  end


  def metacontributions
		@contributor = Contributor.find(params[:id])

    if(!params[:download].nil? and params[:download] == 'csv')
      @metacontributions = @contributor.meta_contributions_by_node
      send_data(meta_contributions_csv(@metacontributions),
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=listed_contributions_for_#{@contributor.fullname.gsub(' ','_')}.csv")
    else
      @metacontributions = @contributor.meta_contributions_by_node.page(params[:page])
    end
  end


  protected

  def contributions_csv(contributions)
    CSV.generate do |csv|
      headers = []
      headers << 'Node Title'
      headers << 'Node ID'
      headers << 'Source URL'
      headers << 'Node Type'
      headers << 'Page ID'
      headers << 'Published URL'
      headers << 'Contributions'
      headers << 'Last Contribution'
      csv << headers
      contributions.each do |node|
        row = []
        row << node.display_title(:truncate => false)
        row << node.id
        row << "http://create.extension.org/node/#{node.id}"
        row << node.node_type
        if(node.has_page?)
          row << node.page.id
          row << "http://www.extension.org/pages/#{node.page.id}/#{node.page.url_title}"
        else
          row << 'n/a'
          row << 'n/a'
        end
        row << NodeActivity.contributions_display(node.contributions)
        row << node.last_contribution_at.to_s
        csv << row
      end
    end
  end

    def meta_contributions_csv(contributions)
    CSV.generate do |csv|
      headers = []
      headers << 'Node Title'
      headers << 'Node ID'
      headers << 'Source URL'
      headers << 'Node Type'
      headers << 'Page ID'
      headers << 'Published URL'
      headers << 'Contributions'
      csv << headers
      contributions.each do |node|
        row = []
        row << node.display_title(:truncate => false)
        row << node.id
        row << "http://create.extension.org/node/#{node.id}"
        row << node.node_type
        if(node.has_page?)
          row << node.page.id
          row << "http://www.extension.org/pages/#{node.page.id}/#{node.page.url_title}"
        else
          row << 'n/a'
          row << 'n/a'
        end
        row << NodeMetacontribution.contributions_display(node.metacontributions)
        csv << row
      end
    end
  end


end