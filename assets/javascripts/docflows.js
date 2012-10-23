jQuery.expr[":"].Contains = jQuery.expr.createPseudo(function(arg) {
    return function( elem ) {
        return jQuery(elem).text().toUpperCase().indexOf(arg.toUpperCase()) >= 0;
    };
});

jQuery(document).ready(function(){

  jQuery('.show_annotation').live("click",function(){
    jQuery(this).hide();
    jQuery(this).nextAll('a.hide_annotation_a').show();
    jQuery(this).nextAll('div.annotation').show();
  })

  jQuery('.hide_annotation').live("click",function(){
    jQuery(this).parent().hide();
    jQuery(this).parent().prevAll('a.hide_annotation_a').hide();
    
    jQuery(this).parent().prevAll('a.show_annotation').show();    
  })

  jQuery('.hide_annotation_a').live("click",function(){
    jQuery(this).hide();    
    jQuery(this).nextAll('div.annotation').hide();

    jQuery(this).prevAll('a.show_annotation').show();
  })

  

  jQuery("#docflow_docflow_category_id").change(function(){
    cat_id = jQuery(this).val().toString();
    approver_id = jQuery("#cat-"+cat_id).val().toString();
    if (jQuery("#is_approver_changed").val() == "n"){
      jQuery("#docflow_versions_attributes_0_approver_id option[value="+approver_id+"]").attr("selected","selected");
    }
  });  

  jQuery("#docflow_versions_attributes_0_approver_id").change(function(){
    jQuery("#is_approver_changed").val("y");
  });
  
  jQuery('.tree_link').live("click",function(){
      fold = jQuery(this).parent();
      if ( jQuery(fold).hasClass("node_expanded") ) {
        jQuery(fold).children("ul").hide();
        jQuery(fold).removeClass('node_expanded');
      }
      else {
        jQuery(fold).children("ul").show();
        jQuery(fold).addClass('node_expanded');
      }
      return false;        
  })

  jQuery('.checklist_edit').live("click",function(){
      dep_id = jQuery(this).attr("href");
      jQuery("#checklist_"+dep_id+"_form").show();
      jQuery("#checklist_"+dep_id+"_list").hide();
      return false;        
  })
  jQuery('.checklist_cancel').live("click",function(){
      dep_id = jQuery(this).attr("href");
      jQuery("#checklist_"+dep_id+"_form").hide();
      jQuery("#checklist_"+dep_id+"_list").show();
      return false;        
  })   

  // jQuery('#filer_people').bind("change keyup input",function(){
  //   if (jQuery(this).val() == ""){
  //     jQuery('#user-list label.one-name').show();
  //   }
  //   else{
  //     jQuery('#user-list label.one-name').hide();
  //     jQuery('#user-list label.one-name:contains('+jQuery(this).val()+')').show();
  //   }
  // });

  jQuery('#filer_groups').bind("change keyup input",function(){
    if (jQuery(this).val() == ""){
      jQuery('#group-list label.one-name').show();
    }
    else{
      jQuery('#group-list label.one-name').hide();
      jQuery('#group-list label.one-name:Contains('+jQuery(this).val()+')').show();
    }
  });

  jQuery('#accept-ver-btn').click(function(){
    if (!confirm(jQuery('#label_docflow_confirm_accept_document').val())) {
      return false;
    }
  });

  jQuery('#cancel-doc-btn').click(function(){
    if (!confirm(jQuery('#label_docflow_confirm_cancel_document').val())) {
      return false;
    }
  });

  jQuery('#show-approve-btn').click(function(){
    jQuery('#approve-form').show();
  });

  jQuery('#close-approve-btn').click(function(){
    jQuery('#approve-form').hide();
  });

  jQuery('a.add_docfile').live('click', function(){
    num_files = jQuery("p.new_attach").size();
    file_type = (jQuery("p.src_file").size() > 0) ? "" : "src_file";
    file_type = (jQuery("p.pub_file").size() > 0) ? file_type : "pub_file";
    file_label = (file_type == "src_file") ? jQuery("#src_file_string").val() : "";
    file_label = (file_type == "pub_file") ? jQuery("#pub_file_string").val() : file_label;

    html = "<p class='new_attach "+file_type+"'>"
    +"<label>"+file_label+"</label>"
    +"<input class='docfile' type=file name='new_files["+num_files+"][file]'> "
    +"<input type=text name='new_files["+num_files+"][description]'>"
    +"<input type=hidden name='new_files["+num_files+"][filetype]' value='"+file_type+"'>"
    +" <a href='#' title='Delete' class='remove_docfile icon-del icon-only'>&nbsp;</a></p>";
    if(file_type == ""){
      jQuery("#new_files").append(html);
    }
    else{
      jQuery("#new_files").prepend(html);
    }
    return false;
  });

  // todo: check files sizes
  jQuery('input.docfile').live('change', function(){
    maxFileSize = jQuery('#docfile_max_size').val();
    if(this.files[0].size > maxFileSize){
        alert("File is too big!");
        jQuery(this).val("");
    }
  });

  jQuery('a.remove_docfile').live('click', function(){
    jQuery(this).parent("p.new_attach").remove();
  });

  jQuery('a.remove_attached_file').live('click', function(){
    if (confirm(jQuery('#label_docflow_confirm_delete_file').val())) {
      jQuery.ajax({ type: 'POST',
                    url: this.href,
                    error: removeDocflowFileFail,
                    success: removeDocflowFileOk,
                    data: {_method:'delete'},
                    dataType: 'json'});
      return false;
    }
    return false;
  });

  jQuery('a.remove_checklist_rec').live('click', function(){
    if (confirm(jQuery('#label_docflow_confirm_delete').val()+jQuery(this).prev('span').html()+' ?')){
      jQuery.ajax({ type: 'POST',
                    url: this.href,
                    error: removeDocflowChecklistFail,
                    success: removeDocflowChecklistOk,
                    data: {_method:'delete'},
                    dataType: 'json'});
      return false;
    }
    return false;
  });

  jQuery('a.tab_selector').click(function(){
    jQuery('div.tab_content').addClass('tab_invisible');
    jQuery('div.tab_content input:checkbox').attr("checked",false);
    jQuery('#department_id option').first().attr("selected","selected");
    id = jQuery(this).attr('id');
    jQuery('a.tab_selector').removeClass('selected');
    jQuery(this).addClass('selected');
    if(id == "tab_users") {jQuery("#users_content").removeClass('tab_invisible');}
    else if(id == "tab_groups") {jQuery("#groups_content").removeClass('tab_invisible');}
    return false;
  });

  // jQuery('#record_add').click(function(){
  //   url_params = jQuery('#checklist_form').attr("action") +'?' + jQuery('#checklist_form').serialize();

  //   jQuery.ajax({ type: 'POST',
  //                 url: url_params,
  //                 error: addDocflowChecklistFail,
  //                 success: addDocflowChecklistOk,
  //                 dataType: 'json'});
  //   jQuery('div.tab_content input:checkbox').attr("checked",false);
  //   jQuery('#department_id option').first().attr("selected","selected");

  //   return false;
  // });
  if(jQuery('#content-checklists li').size() < 1){
    jQuery('#no_checklist_records').show();
  }

});


function addDocflowChecklistOk(resp){
  if (resp.result != 'ok'){
    alert(jQuery('#label_docflow_request_failed').val()+'\n'+resp.msg);
    return false;
  }
  unsaved = ""
  if (resp.saved instanceof Array){
    for(i=0; i< resp.saved.size();i++){
      rec = resp.saved[i];
      if(rec.err == ""){
        jQuery('#content-checklists').append("<li class='checklist_record' id='ch"+rec.id.toString()+"'><span class='right-marg'>"+rec.name+"</span></li>");
        jQuery('#ch'+rec.id.toString()).append("<a href='/docflow_versions/"+rec.docflow_version_id.toString()+"/remove_checklist/"+rec.id.toString()+"' class='remove_checklist_rec icon icon-del'></a>");
      }
      else{
        unsaved = unsaved + "\n" + rec.name
      }
    }
    if(unsaved != ""){
      alert(jQuery('#label_docflow_check_list_similar_records').val()+'\n' + unsaved)
    }
  }
  else {
    alert(jQuery('#label_docflow_something_wrong').val())
  }
}

function addDocflowChecklistFail(resp){
  alert(jQuery('#label_docflow_request_failed').val());
}
// unility function for debuging 1st-level props of an object
function fnShowProps(obj){
    var result = "";
    for (var i in obj)
        result += "obj." + i + " = " + obj[i] + "\n";
    return(result);
}

function removeDocflowFileOk(resp){
  if(resp.result == "ok") {
    jQuery("#df"+resp.id).remove();
  }
  else {
    alert(jQuery('#label_docflow_deletion_file_failed').val()+'\n'+ resp.msg);
  }
  return false;
}

function removeDocflowFileFail(resp){
  alert(jQuery('#label_docflow_request_failed').val());
  return false;
}

function removeDocflowChecklistOk(resp){
  if(resp.result == "ok") {
    jQuery("#ch"+resp.id).remove();
    // alert(jQuery("#content-checklists").children(":first-child").html())
    if(jQuery("#content-checklists").children(":first").hasClass('br_space')){
      jQuery("#content-checklists").children(":first").remove();
    }
    if(jQuery("#content-checklists li").size() < 1){
      jQuery('#no_checklist_records').show();
    }
  }
  else {
    alert(jQuery('#label_docflow_request_failed').val()+'\n'+resp.msg);
  }
  return false;
}

function removeDocflowChecklistFail(resp){
  alert(jQuery('#label_docflow_request_failed').val());
  return false;
}

function sort_tree(tree_id){
  jQuery("#"+tree_id+" ul.tree_container").each(function (i, el) {
    first_leaf = jQuery(el).children("li.tree_leaf").first();
    if ( jQuery(first_leaf).length ) {
      jQuery(el).children("li.tree_fold").each(function(k, elem){
        jQuery(elem).insertBefore(first_leaf)
      })
    }        
  })    
}

function clear_tree(tree_id){
  jQuery("#"+tree_id+" li.tree_fold:not(li.tree_fold:has(li.tree_leaf))").remove();
}