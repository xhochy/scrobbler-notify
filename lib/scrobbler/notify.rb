require 'rubygems'

require 'notifier_wrapper'
require 'scrobbler'
require 'tempfile'

module Scrobbler
  class Notify < NotifierWrapper
    alias :notify_raw :notify
    
    def initialize(user, options = {})
        options = {:should_play => true}.merge(options)
        super(options)
        @should_play = options[:should_play]
        @user = user
    end
    
    # This should be called contionously as this checks for a new track
    def trigger
        latest_track = @user.recent_tracks(true, :limit => 1).first
        if @track.nil? || @track != latest_track
            @track = latest_track
            notify if latest_track.now_playing || (not @should_play)
        end
    end
    
    # Show a notification that the track has changed
    def notify
        image = image_get
        params = {:timeout => 5}
        params[:icon] = image unless image.nil?
        notify_raw("Last.fm - #{@user.username}", "#{@track.artist.name} - #{@track.name}", params) 
        image_clean
    end

    # Download a image releated to the played track    
    def image_get
        @image = Tempfile.new('scrobbler-notify')
        if @track.image(:small).nil? || @track.image(:small).empty?
            if @track.album.nil? || @track.album.image(:small).nil? || @track.album.image(:small).empty?
                if @track.artist.nil? || @track.artist.image(:small).nil? || @track.artist.image(:small).empty?
                    image_uri = nil
                else
                    image_uri = URI.parse(@track.artist.image(:small))
                end
            else
                image_uri = URI.parse(@track.album.image(:small))
            end
        else
            image_uri = URI.parse(@track.image(:small))
        end
        @image.print(Net::HTTP.get(image_uri)) unless image_uri.nil?
        @image.close
        @image.path
    end
    
    # Cleanup everthing needed to fetch the image
    def image_clean
        @image.unlink
    end
    
  end # Notify
end # Scrobbler
