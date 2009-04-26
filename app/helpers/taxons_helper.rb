module TaxonsHelper
  def breadcrumbs(taxon, separator="&nbsp;&raquo;&nbsp;")
    return "" if current_page?("/")
    crumbs = [content_tag(:li, link_to("Home" , root_path) + separator)]
    if taxon
      crumbs << content_tag(:li, link_to(t('products') , products_path) + separator)
      crumbs << taxon.ancestors.reverse.collect { |ancestor| content_tag(:li, link_to(ancestor.name , seo_url(ancestor)) + separator) } unless taxon.ancestors.empty?
      crumbs << content_tag(:li, content_tag(:span, taxon.name))
    else
      crumbs << content_tag(:li, content_tag(:span, t('products')))
    end
    crumb_list = content_tag(:ul, crumbs)

    content_tag(:div, crumb_list + content_tag(:br, nil, :class => 'clear'), :class => 'breadcrumbs')
  end

  
  # Retrieves the collection of products to display when "previewing" a taxon.  This is abstracted into a helper so 
  # that we can use configurations as well as make it easier for end users to override this determination.  One idea is
  # to show the most popular products for a particular taxon (that is an exercise left to the developer.) 
  def taxon_preview(taxon)
    products = taxon.products.active[0..4]
    return products unless products.size < 5
    if Spree::Config[:show_descendents]
      taxon.descendents.each do |taxon|
        products += taxon.products.active[0..4]
        break if products.size >= 5
      end
    end
    products[0..4]
  end
end