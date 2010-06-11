# Copyright (C) 2009 Pascal Rettig.

class Manage::UsersController < CmsController # :nodoc: all

  # need to be at least a client admin
  permit ['system_admin','client_admin']
  layout "manage"

  def index
    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], 
                    "Client Users"
                 ],"system"
    
    if self.system_admin?
      session[:active_client_company] ||= self.client_user.client_id 
      session[:active_client_company] = params[:active_client_company] if params[:active_client_company]
      
      @active_client = session[:active_client_company]
      @client = Client.find(@active_client)
      @clients = Client.find(:all,:order => 'name')
      @users = @client.client_users.find(:all, :order => 'username')
    else
      @client = self.client
      @users = @client.client_users.find(:all, :order => 'username', :conditions => {:system_admin => false})
    end
  
    render :action => 'list'
  end
  
  def edit
    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], 
                    [ "Client Users", url_for(:action => 'index') ],
                    "Edit User"
                 ],"system"
  
    @client_user = self.client.client_users.find_by_id(params[:path][0]) || self.client.client_users.new(:client_admin => false, :system_admin => false)
    @create_user = @client_user.id ?  false : true

    if @client_user.id
      unless self.system_admin?
        return redirect_to :action => 'index' if @client_user.system_admin? || @client_user.client_id != self.client.id
      end
    end

    if request.post?
      if params[:commit]
        params[:client_user][:client_admin] = false unless params[:client_user][:client_admin]
        del params[:client_user][:system_admin] if params[:client_user][:system_admin]
        params[:client_user][:client_id] = self.client_user.client_id
        if @client_user.update_attributes(params[:client_user].slice(:username, :password, :domain_database_id, :client_admin))
          redirect_to :action => 'index'
          return
        end
      else
        redirect_to :action => 'index'
        return
      end
    end
  end
  
  def edit_all
    return redirect_to :action => 'edit', :path => params[:path] unless self.system_admin?

    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], 
                    [ "Client Users", url_for(:action => 'index') ],
                    "Edit User"
                 ],"system"
     # edit all func is only for system admins
    permit 'system_admin' do
      @client_user = ClientUser.find_by_id(params[:path][0]) || ClientUser.new(:client_id => session[:active_client_company], :client_admin => false, :system_admin => false)
      @create_user = @client_user.id ?  false : true
    
      
      if request.post? 
        if params[:commit]
          params[:client_user][:client_admin] = false unless params[:client_user][:client_admin]
          params[:client_user][:system_admin] = false unless params[:client_user][:system_admin]
          
          if @client_user.update_attributes(params[:client_user])
            flash[:notice] = "Saved %s" / @client_user.name
            redirect_to :action => 'index'
            return
          end
        else
          redirect_to :action => 'index'
          return
        end
      end
    end
  
    render :action => 'edit'
  end

  def destroy
    if self.system_admin?
      @client_user = ClientUser.find_by_id params[:path][0]
    else
      @client_user = self.client.client_users.find_by_id params[:path][0]
      @client_user = nil if @client_user && @client_user.system_admin?
    end

    @client_user = nil if @client_user && @client_user.id == self.client_user.id

    if @client_user && request.post?
      if @client_user.destroy
        flash[:notice] = "Deleted User: #{@client_user.username}"
      end
    end

    redirect_to :action => 'index'
  end

  protected

  include Manage::SystemController::Base

end
