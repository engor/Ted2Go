
#include "litehtml_glue.h"

//**** *bb_litehtml_document_container *****

litehtml::uint_ptr bb_litehtml_document_container::create_font( const litehtml::tchar_t *faceName,int size,int weight,litehtml::font_style style,unsigned int decoration,litehtml::font_metrics *fm ){

	bbObject *font=_create_font( faceName,size,weight,style,decoration,fm );
	return font;
}

void bb_litehtml_document_container::delete_font( litehtml::uint_ptr hFont ){

	bbObject *font=(bbObject*)hFont;
	_delete_font( font );
}

int	bb_litehtml_document_container::text_width( const litehtml::tchar_t *text,litehtml::uint_ptr hFont ){

	bbObject *font=(bbObject*)hFont;
	return _text_width( text,font );
}

void bb_litehtml_document_container::draw_text( litehtml::uint_ptr hHdc,const litehtml::tchar_t *text,litehtml::uint_ptr hFont,litehtml::web_color color,const litehtml::position &pos ){

	bbObject *hdc=(bbObject*)hHdc;
	bbObject *font=(bbObject*)hFont;
	_draw_text( hdc,text,font,&color,(litehtml::position*)&pos );
}

int bb_litehtml_document_container::pt_to_px( int pt ){

	return _pt_to_px( pt );
}

int	bb_litehtml_document_container::get_default_font_size()const{

	return ((bb_litehtml_document_container*)this)->_get_default_font_size();
}

const litehtml::tchar_t *bb_litehtml_document_container::get_default_font_name()const{

	bbString name=((bb_litehtml_document_container*)this)->_get_default_font_name();
	return name.c_str();//<litehtml::tchar_t>();
}

void bb_litehtml_document_container::draw_list_marker( litehtml::uint_ptr hHdc,const litehtml::list_marker &marker ){

	bbObject *hdc=(bbObject*)hHdc;
	_draw_list_marker( hdc,(litehtml::list_marker*)&marker );
}

void bb_litehtml_document_container::load_image( const litehtml::tchar_t *src,const litehtml::tchar_t *baseurl,bool redraw_on_ready ){

	_load_image( src,"",redraw_on_ready );//baseurl,redraw_on_ready );
}

void bb_litehtml_document_container::get_image_size( const litehtml::tchar_t *src,const litehtml::tchar_t *baseurl,litehtml::size &sz ){

	_get_image_size( src,"",&sz );//baseurl,&sz );
}

void bb_litehtml_document_container::draw_background( litehtml::uint_ptr hHdc,const litehtml::background_paint &bg ){

	bbObject *hdc=(bbObject*)hHdc;
	_draw_background( hdc,bg.image.c_str(),"",(litehtml::background_paint*)&bg );
}

void bb_litehtml_document_container::draw_borders( litehtml::uint_ptr hHdc,const litehtml::borders &borders,const litehtml::position &draw_pos,bool root ){

	bbObject *hdc=(bbObject*)hHdc;
	_draw_borders( hdc,(litehtml::borders*)&borders,(litehtml::position*)&draw_pos,root );
}

void bb_litehtml_document_container::set_caption( const litehtml::tchar_t *caption ){
	_set_caption( caption );
}

void bb_litehtml_document_container::set_base_url( const litehtml::tchar_t *base_url ){
	_set_base_url( base_url );
}

void bb_litehtml_document_container::link( const std::shared_ptr<litehtml::document> &doc,const litehtml::element::ptr &el ){
}

void bb_litehtml_document_container::on_anchor_click( const litehtml::tchar_t *url,const litehtml::element::ptr &el ){
	_on_anchor_click( url );
}

void bb_litehtml_document_container::set_cursor( const litehtml::tchar_t *cursor ){
	_set_cursor( cursor );
}

void bb_litehtml_document_container::transform_text( litehtml::tstring &text,litehtml::text_transform tt ){

//	_transform_text( text,tt );
}

void bb_litehtml_document_container::import_css( litehtml::tstring &text,const litehtml::tstring &url,litehtml::tstring &baseurl ){

	bbString css=_import_css( url.c_str(),"" );
	
	text=css.c_str();
//	text=static_cast<const litehtml::tchar_t*>( css );

	baseurl="";
}

void bb_litehtml_document_container::set_clip( const litehtml::position &pos,const litehtml::border_radiuses &bdr_radius,bool valid_x,bool valid_y ){

	_set_clip( (litehtml::position*)&pos,(litehtml::border_radiuses*)&bdr_radius );
}

void bb_litehtml_document_container::del_clip(){

	_del_clip();
}

void bb_litehtml_document_container::get_client_rect( litehtml::position &client )const{

	((bb_litehtml_document_container*)this)->_get_client_rect( &client );
}

std::shared_ptr<litehtml::element>	bb_litehtml_document_container::create_element( 
const litehtml::tchar_t *tag_name,
const litehtml::string_map &attributes,
const std::shared_ptr<litehtml::document> &doc ){
															 
	return nullptr;
}

void bb_litehtml_document_container::get_media_features( litehtml::media_features &media )const{

	((bb_litehtml_document_container*)this)->_get_media_features( &media );
}

void bb_litehtml_document_container::get_language( litehtml::tstring &language,litehtml::tstring &culture )const{
	((bb_litehtml_document_container*)this)->_get_language();
	((bb_litehtml_document_container*)this)->_get_culture();
}

//**** *bb_litehtml_context ****

bb_litehtml_context::bb_litehtml_context(){
}

void bb_litehtml_context::load_master_stylesheet( bbString master_css ){

	litehtml::context::load_master_stylesheet( bbCString( master_css ) );
}

//**** *bb_litehtml_document *****

bb_litehtml_document::bb_litehtml_document( bbString source,bb_litehtml_document_container *container,bb_litehtml_context *context ){

	_document=litehtml::document::createFromUTF8( bbCString( source ),container,context );
	
	_container=container;
	_context=context;
}

bb_litehtml_document::~bb_litehtml_document(){
}
	
void bb_litehtml_document::render( int max_width ){
	_document->render( max_width );
}

void bb_litehtml_document::draw( bbObject *hdc,int x,int y,litehtml::position *clip ){
	_drawing=hdc;
	_document->draw( (litehtml::uint_ptr)hdc,x,y,clip );
	_drawing=nullptr;
}

int bb_litehtml_document::width(){
	return _document->width();
}

int bb_litehtml_document::height(){
	return _document->height();
}

void bb_litehtml_document::gcMark(){
	bbGCMark( _container );
	bbGCMark( _context );
	bbGCMark( _drawing );
}

void bb_litehtml_document::media_changed(){

	_document->media_changed();
}

void bb_litehtml_document::on_mouse_over( int x,int y,int client_x,int client_y ){
	
	litehtml::position::vector redraw_boxes;

	_document->on_mouse_over( x,y,client_x,client_y,redraw_boxes );
}
	
void bb_litehtml_document::on_lbutton_down( int x,int y,int client_x,int client_y ){
	
	litehtml::position::vector redraw_boxes;

	_document->on_lbutton_down( x,y,client_x,client_y,redraw_boxes );
}

void bb_litehtml_document::on_lbutton_up( int x,int y,int client_x,int client_y ){
	
	litehtml::position::vector redraw_boxes;

	_document->on_lbutton_up( x,y,client_x,client_y,redraw_boxes );
}

void bb_litehtml_document::on_mouse_leave(){

	litehtml::position::vector redraw_boxes;

	_document->on_mouse_leave( redraw_boxes );
}
