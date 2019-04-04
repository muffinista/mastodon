# frozen_string_literal: true

module DatacenterConcern
  extend ActiveSupport::Concern

  included do
    before_action :prevent_datacenters, only: [:new, :create]
  end

  def prevent_datacenters
    begin
      require 'ipcat'

      if IPCat.datacenter?(request.remote_ip) != nil
        redirect_to '/datacenters.html'
      elsif File.exist?(Rails.root.join('blocks.txt'))
        require 'ipaddr'

        has_block = File.read(Rails.root.join('blocks.txt')).split(/\n/).find { |ip|
          net = IPAddr.new(ip)
          net.include?(request.remote_ip)
        }

        if has_block
          redirect_to '/datacenters.html'
        end
      end

    rescue

    end
  end
end
