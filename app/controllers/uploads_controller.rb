# frozen_string_literal: true

class UploadsController < ApplicationController
  respond_to :html, :xml, :json, :js
  skip_before_action :verify_authenticity_token, only: [:create], if: -> { request.xhr? }

  def new
    @upload = authorize Upload.new(uploader: CurrentUser.user, uploader_ip_addr: CurrentUser.ip_addr, source: params[:url], referer_url: params[:ref], **permitted_attributes(Upload))
    respond_with(@upload)
  end

  def create
    @upload = authorize Upload.new(uploader: CurrentUser.user, uploader_ip_addr: CurrentUser.ip_addr, **permitted_attributes(Upload))
    @upload.save
    respond_with(@upload)
  end

  def index
    @mode = params.fetch(:mode, "gallery")

    @defaults = {}
    @defaults[:uploader_id] = params[:user_id]
    @defaults[:status] = "completed" if request.format.html?
    @limit = params.fetch(:limit, CurrentUser.user.per_page).to_i.clamp(0, PostSets::Post::MAX_PER_PAGE)
    @preview_size = params[:size].presence || cookies[:post_preview_size].presence || MediaAssetGalleryComponent::DEFAULT_SIZE

    @uploads = authorize Upload.visible(CurrentUser.user).paginated_search(params, limit: @limit, count_pages: true, defaults: @defaults)
    @uploads = @uploads.includes(:uploader, :posts, upload_media_assets: :media_asset) if request.format.html?

    respond_with(@uploads, include: { upload_media_assets: { include: :media_asset }})
  end

  def show
    @upload = authorize Upload.find(params[:id])
    @preview_size = params[:size].presence || cookies[:post_preview_size].presence || MediaAssetGalleryComponent::DEFAULT_SIZE

    if request.format.html? && @upload.media_asset_count == 1 && @upload.media_assets.first&.post.present?
      flash[:notice] = "Duplicate of post ##{@upload.media_assets.first.post.id}"
      redirect_to @upload.media_assets.first.post
    elsif request.format.html? && @upload.media_asset_count > 1
      redirect_to [@upload, UploadMediaAsset]
    else
      respond_with(@upload, include: { upload_media_assets: { include: :media_asset }})
    end
  end
end
