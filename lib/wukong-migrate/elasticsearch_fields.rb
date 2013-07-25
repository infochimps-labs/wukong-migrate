# -*- coding: utf-8 -*-
class EsField
  include Gorillib::Model
  
  field :index_as,            String,   doc: 'The name of the field that will be stored in the index. Defaults to the property/field name.'
  field :store,               String,   doc: 'Set to yes to store actual field in the index, no to not store it. Defaults to no (note, the JSON document itself is stored, and it can be retrieved from it).'
  field :index,               :boolean, doc: 'Set to analyzed for the field to be indexed and searchable after being broken down into token using an analyzer. not_analyzed means that its still searchable, but does not go through any analysis process or broken down into tokens. no means that it won’t be searchable at all (as an individual field; it may still be included in _all). Setting to no disables include_in_all. Defaults to analyzed.'
  field :boost,               Float,    doc: 'The boost value. Defaults to 1.0.'
  field :include_in_all,      :boolean, doc: 'Should the field be included in the _all field (if enabled). If index is set to no this defaults to false, otherwise, defaults to true or to the parent object type setting.'

  def to_mapping
    attributes.compact_blank.merge(type: short_type)
  end
end

class EsString < EsField
  field :index, String, default: 'not_analyzed', doc: 'Set to analyzed for the field to be indexed and searchable after being broken down into token using an analyzer. not_analyzed means that its still searchable, but does not go through any analysis process or broken down into tokens. no means that it won’t be searchable at all (as an individual field; it may still be included in _all). Setting to no disables include_in_all. Defaults to analyzed.'
  field :term_vector,         String,   doc: 'Possible values are no, yes, with_offsets, with_positions, with_positions_offsets. Defaults to no.'
  field :null_value,          String,   doc: 'When there is a (JSON) null value for the field, use the null_value as the field value. Defaults to not adding the field at all.'
  field :omit_norms,          String,   doc: 'Boolean value if norms should be omitted or not. Defaults to false for analyzed fields, and to true for not_analyzed fields.'
  field :index_options,       String,   doc: 'Allows to set the indexing options, possible values are docs (only doc numbers are indexed), freqs (doc numbers and term frequencies), and positions (doc numbers, term frequencies and positions). Defaults to positions for analyzed fields, and to docs for not_analyzed fields. Since 0.20.'
  field :analyzer,            String,   doc: 'The analyzer used to analyze the text contents when analyzed during indexing and when searching using a query string. Defaults to the globally configured analyzer.'
  field :index_analyzer,      String,   doc: 'The analyzer used to analyze the text contents when analyzed during indexing.'
  field :search_analyzer,     String,   doc: 'The analyzer used to analyze the field when part of a query string. Can be updated on an existing field.'
  field :ignore_above,        Integer,  doc: 'The analyzer will ignore strings larger than this size. Useful for generic not_analyzed fields that should ignore long text. (since @0.19.9).'
  field :position_offset_gap, Integer,  doc: 'Position increment gap between field instances with the same field name. Defaults to 0.'
  
  def short_type() 'string'  ; end
end

class EsNumeric < EsField
  field :precision_step,      Integer,  doc: 'The precision step (number of terms generated for each number value). Defaults to 4.'
  field :ignore_malformed,    :boolean, doc: 'Ignored a malformed number. Defaults to false. (Since @0.19.9).'
end

class EsInteger < EsNumeric
  field :null_value,          Integer,  doc: 'When there is a (JSON) null value for the field, use the null_value as the field value. Defaults to not adding the field at all.'  
  def short_type() 'integer' ; end
end

class EsFloat < EsNumeric
  field :null_value,          Float,    doc: 'When there is a (JSON) null value for the field, use the null_value as the field value. Defaults to not adding the field at all.'  
  def short_type() 'float'   ; end
end

class EsDate < EsNumeric
  field :format,              String,   doc: 'The date format. Defaults to dateOptionalTime.'
  field :null_value,          Date,     doc: 'When there is a (JSON) null value for the field, use the null_value as the field value. Defaults to not adding the field at all.'
  def short_type() 'date'    ; end
end

class EsBoolean < EsField
  field :null_value,          :boolean, doc: 'When there is a (JSON) null value for the field, use the null_value as the field value. Defaults to not adding the field at all.'
  def short_type() 'boolean' ; end
end

class EsIpAddress < EsNumeric  
  def short_type() 'ip'      ; end
end
