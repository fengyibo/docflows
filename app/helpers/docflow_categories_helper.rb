module DocflowCategoriesHelper

  def li_tree(ns)
    # lft,rgt = 0,0
    # max_rgt = rgt
    # # result = "==============[li start]============"
    # ns.each do |n|

    #   if n.lft > lft+1
    #     result += "</li>" if rgt+1 == n.lft # neighbours - same level
    #     result += "</li></ul>"*(n.lft-rgt-1) if (n.lft-rgt) > 1 # level (s) up
    #   else #if n.lft == lft+1
    #     result += "<ul>"
    #   end
    #   # else nothing to close - new sub node
    #   result += "<li id="+n.id.to_s+" style='margin-left:20px;'>"+n.name+" "+image_tag("bullet_delete.png", :id => "dc#{n.id}_del", :class => "combox_inf btn")


    #   lft,rgt = n.lft,n.rgt
    #   max_rgt = (max_rgt > rgt) ? max_rgt : rgt
    # end
    # result += "</li></ul>"*(max_rgt-rgt+1)
    # #result += "==============[li end]============"
    #render :inline => result
  end

  def div_tree(ns)
    lft,rgt = 0,0
    pad_left = -20
    max_rgt = rgt
    result = ""
    ns.each do |n|

      if n.lft > lft+1
        # neighbours - same level, need to close current element
        # result += "</div>" if rgt+1 == n.lft

        # go to level(s) up - close such numer of elements as levels difference,
        # but don't close parent due possibility of next childs on same level
        # result += "</div>"*(n.lft-rgt) if (n.lft-rgt) > 1
        pad_left -= 20*(n.lft-rgt-1) if (n.lft-rgt) > 1
      elsif n.lft == lft + 1
        pad_left += 20
      end
      # else nothing to close - new sub node
      result += "<div id="+n.id.to_s+" class='bottom-bordered'>"
      result += "<table class='invisi-table'><tr>"
      result += content_tag(:td, link_to(n.name, edit_docflow_category_path(n)), :style => "padding-left: #{pad_left}px;")
      result += content_tag(:td,
                    link_to('&nbsp;'.html_safe, new_docflow_category_path(:parent_id => n.id),:class => 'icon-add icon-only')+" "+
                    link_to('&nbsp;'.html_safe, docflow_category_path(n), :confirm => l(:label_docflow_delete_category_confirm),
                        :method => :delete, :action => :destory, :class => 'icon-del icon-only'),
                  :style => "width:40px")
      result += "</tr></table></div>"

      lft,rgt = n.lft,n.rgt
      max_rgt = (max_rgt > rgt) ? max_rgt : rgt
    end
    # tail close - as many brackets as level's between last element and parent. +1 bracket to close parent
    # result += "</div>"*(max_rgt-rgt+1)
    render :inline => result # todo: .html_safe ???
  end

  def div_tree_nested(ns)
    lft,rgt = 0,0
    pad_left = -20
    max_rgt = rgt
    result = ""
    ns.each do |n|

      if n.lft > lft+1
        # neighbours - same level, need to close current element
        result += "</div>" if rgt+1 == n.lft

        # go to level(s) up - close such numer of elements as levels difference,
        # but don't close parent due possibility of next childs on same level
        result += "</div>"*(n.lft-rgt) if (n.lft-rgt) > 1
        pad_left -= 20 if (n.lft-rgt) > 1
      elsif n.lft == lft + 1
        pad_left += 20
      end
      # else nothing to close - new sub node
      result += "<div id="+n.id.to_s+">"
      result += "<table class='invisi-table'><tr>"
      result += content_tag(:td, link_to(n.name, edit_docflow_category_path(n)), :style => "padding-left: #{pad_left}px;", :class => 'bottom-bordered')
      result += content_tag(:td,
                    link_to('', new_docflow_category_path(:parent_id => n.id),:class => 'icon icon-add')+" "+
                    link_to('', docflow_category_path(n), :confirm => l(:label_docflow_delete_category_confirm),
                        :method => :delete, :action => :destory, :class => 'icon icon-del'),
                  :style => "width:40px")
      result += "</tr></table>"

      lft,rgt = n.lft,n.rgt
      max_rgt = (max_rgt > rgt) ? max_rgt : rgt
    end
    # tail close - as many brackets as level's between last element and parent. +1 bracket to close parent
    result += "</div>"*(max_rgt-rgt+1)
    render :inline => result # todo: .html_safe ???
  end

end
