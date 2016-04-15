
#ifndef BB_LITEHTML_GLUE_H
#define BB_LITEHTML_GLUE_H

#include <bbmonkey.h>
#include <litehtml.h>

class bb_litehtml_document_container : public bbObject,public litehtml::document_container{

	protected:

	virtual bbObject*	_create_font( bbString faceName,bbInt size,bbInt weight,litehtml::font_style style,bbUInt decoration,litehtml::font_metrics *fm )=0;

	virtual void		_delete_font( bbObject *font )=0;

	virtual bbInt		_text_width( bbString text,bbObject *font )=0;

	virtual void		_draw_text( bbObject *hdc,bbString text,bbObject *font,litehtml::web_color *color,litehtml::position *pos )=0;
	
	virtual bbInt		_pt_to_px( int pt )=0;
	
	virtual bbInt		_get_default_font_size()=0;
	
	virtual bbString	_get_default_font_name()=0;
	
	virtual void		_draw_list_marker( bbObject *hdc,litehtml::list_marker *marker )=0;
	
	virtual void		_load_image( bbString src,bbString baseurl,bbBool redraw_on_ready )=0;
	
	virtual void		_get_image_size( bbString src,bbString baseurl,litehtml::size *sz )=0;
	
	virtual void		_draw_background( bbObject *hdc,bbString img_src,bbString img_baseurl,litehtml::background_paint *bg )=0;

	virtual void		_draw_borders( bbObject *hdc,litehtml::borders *borders,litehtml::position *draw_pos,bbBool root )=0;
	
	virtual void		_set_caption( bbString caption )=0;
	
	virtual void		_set_base_url( bbString base_url )=0;

	virtual void		_on_anchor_click( bbString url )=0;
	
	virtual void		_set_cursor( bbString cursor )=0;
	
	virtual bbString	_import_css( bbString url,bbString baseurl )=0;
	
	virtual void		_set_clip( litehtml::position *pos,litehtml::border_radiuses *bdr_radius )=0;
	
	virtual void		_del_clip()=0;
	
	virtual void		_get_client_rect( litehtml::position *client )=0;
	
	virtual void		_get_media_features( litehtml::media_features *media )=0;
	
	virtual bbString	_get_language()=0;
	
	virtual bbString	_get_culture()=0;

	//**** *document_container ******

	litehtml::uint_ptr	create_font( const litehtml::tchar_t *faceName,int size,int weight,litehtml::font_style italic,unsigned int decoration,litehtml::font_metrics *fm );
	
	void				delete_font( litehtml::uint_ptr hFont );
	
	int					text_width( const litehtml::tchar_t *text,litehtml::uint_ptr hFont );
	
	void				draw_text( litehtml::uint_ptr hdc,const litehtml::tchar_t *text,litehtml::uint_ptr hFont,litehtml::web_color color,const litehtml::position &pos );
	
	int					pt_to_px( int pt );
	
	int					get_default_font_size()const;
	
	const litehtml::tchar_t *get_default_font_name()const;	
	
	void				draw_list_marker( litehtml::uint_ptr hdc,const litehtml::list_marker &marker );
	
	void				load_image( const litehtml::tchar_t *src,const litehtml::tchar_t *baseurl,bool redraw_on_ready );
	
	void				get_image_size( const litehtml::tchar_t *src,const litehtml::tchar_t *baseurl,litehtml::size &sz );
	
	void				draw_background( litehtml::uint_ptr hdc,const litehtml::background_paint &bg );
	
	void				draw_borders( litehtml::uint_ptr hdc,const litehtml::borders &borders,const litehtml::position &draw_pos,bool root );
	
	void				set_caption( const litehtml::tchar_t *caption );
	
	void				set_base_url( const litehtml::tchar_t *base_url );
	
	void				link( const std::shared_ptr<litehtml::document> &doc,const litehtml::element::ptr &el );
	
	void				on_anchor_click( const litehtml::tchar_t *url,const litehtml::element::ptr &el );
	
	void				set_cursor( const litehtml::tchar_t *cursor );
	
	void				transform_text( litehtml::tstring &text,litehtml::text_transform tt );
	
	void				import_css( litehtml::tstring &text,const litehtml::tstring &url,litehtml::tstring &baseurl );
	
	void				set_clip( const litehtml::position &pos,const litehtml::border_radiuses &bdr_radius,bool valid_x,bool valid_y );
	
	void				del_clip();
	
	void				get_client_rect( litehtml::position &client )const;
	
	std::shared_ptr<litehtml::element>	create_element( const litehtml::tchar_t *tag_name,
																 const litehtml::string_map &attributes,
																 const std::shared_ptr<litehtml::document> &doc );
	
	void				get_media_features( litehtml::media_features &media )const;
	
	void				get_language( litehtml::tstring &language,litehtml::tstring  &culture )const;
};

class bb_litehtml_context : public bbObject,public litehtml::context{

	public:

	bb_litehtml_context();
	
	void				load_master_stylesheet( bbString master_css );
	
};

class bb_litehtml_document : public bbObject{

	public:
	
	bb_litehtml_document( bbString source,bb_litehtml_document_container *container,bb_litehtml_context *context );
	
	~bb_litehtml_document();
	
	void				render( int max_width );
	
	void				draw( bbObject *hdc,int x,int y,litehtml::position *clip );
	
	int					width();
	
	int					height();
	
	void				media_changed();
	
	void				on_mouse_over( int x,int y,int client_x,int client_y ); 
	
	void				on_lbutton_down( int x,int y,int client_x,int client_y ); 

	void				on_lbutton_up( int x,int y,int client_x,int client_y ); 

	void				on_mouse_leave();

	private:
	
	litehtml::document::ptr _document{};
	
	bb_litehtml_document_container *_container{};
	bb_litehtml_context *_context{};
	bbObject *_drawing{};
	
	void gcMark();
};

#endif
