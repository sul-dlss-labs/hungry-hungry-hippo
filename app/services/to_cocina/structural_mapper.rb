# frozen_string_literal: true

module ToCocina
  # Maps Content to a Cocina structural
  class StructuralMapper
    ID_NAMESPACE = 'https://cocina.sul.stanford.edu'

    def self.call(...)
      new(...).call
    end

    # @param [WorkForm] work_form
    # @param [Content] content
    def initialize(work_form:, content:)
      @work_form = work_form
      @content = content
    end

    def call
      if new_object?
        Cocina::Models::RequestDROStructural.new(params)
      else
        Cocina::Models::DROStructural.new(params)
      end
    end

    private

    attr_reader :work_form, :content

    def new_object?
      work_form.druid.blank?
    end

    def params
      {
        contains: content.content_files.map { |content_file| fileset_params_for(content_file) }
      }
    end

    def fileset_params_for(content_file)
      # one file per fileset
      {
        type: Cocina::Models::FileSetType.file,
        version: work_form.version,
        label: content_file.label,
        externalIdentifier: fileset_external_identifier_for(content_file),
        structural: {
          contains: [file_params_for(content_file)]
        }
      }.compact
    end

    def file_params_for(content_file)
      {
        type: Cocina::Models::ObjectType.file,
        version: work_form.version,
        label: content_file.label,
        filename: content_file.filename,
        access: { view: 'world', download: 'world' },
        administrative: { publish: true, sdrPreserve: true, shelve: true },
        hasMimeType: content_file.mime_type,
        hasMessageDigests: message_digests_for(content_file),
        size: content_file.size,
        externalIdentifier: file_external_identifier_for(content_file)
      }.compact
    end

    def fileset_external_identifier_for(content_file)
      if new_object?
        nil
      elsif content_file.fileset_external_identifier.present?
        content_file.fileset_external_identifier
      else
        # see https://github.com/sul-dlss/dor-services-app/blob/main/app/services/cocina/id_generator.rb
        "#{ID_NAMESPACE}/fileSet/#{bare_druid}-#{SecureRandom.uuid}"
      end
    end

    def file_external_identifier_for(content_file)
      if new_object?
        nil
      elsif content_file.fileset_external_identifier.present?
        content_file.external_identifier
      else
        # see https://github.com/sul-dlss/dor-services-app/blob/main/app/services/cocina/id_generator.rb
        "#{ID_NAMESPACE}/file/#{bare_druid}-#{SecureRandom.uuid}"
      end
    end

    def bare_druid
      work_form.druid.delete_prefix('druid:')
    end

    def message_digests_for(content_file)
      [].tap do |digests|
        digests << { type: 'md5', digest: content_file.md5_digest } if content_file.md5_digest.present?
        digests << { type: 'sha1', digest: content_file.sha1_digest } if content_file.sha1_digest.present?
      end
    end
  end
end
