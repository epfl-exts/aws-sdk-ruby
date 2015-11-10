require 'uri'

module Aws
  module S3
    class Bucket

      # Deletes all objects and versioned objects from this bucket
      #
      # @example
      #
      #   bucket.clear!
      #
      # @return [void]
      def clear!
        object_versions.delete
      end

      # Deletes all objects and versioned objects from this bucket and
      # then deletes the bucket.
      #
      # @example
      #
      #   bucket.delete!
      #
      # @option options [Float]  :initial_wait (1.3) Initial wait time. Exponentially increased for each attempt.
      #                 [Fixnum] :max_attempts (3) Maximum number of attempts to make before raising Errors::BucketNotEmpty.
      #
      # @return [void]
      DELETE_BANG_DEFAULTS = { initial_wait: 1.3, max_attempts: 3 }

      def delete! options = { }
        options = DELETE_BANG_DEFAULTS.merge options

        attempts = 0

        begin
          clear!
          delete
        rescue Errors::BucketNotEmpty => e
          attempts += 1

          raise e if attempts >= options[:max_attempts]

          Kernel.sleep options[:initial_wait] ** attempts

          retry
        end
      end

      # Returns a public URL for this bucket.
      #
      #     bucket = s3.bucket('bucket-name')
      #     bucket.url
      #     #=> "https://bucket-name.s3.amazonaws.com"
      #
      # You can pass `virtual_host: true` to use the bucket name as the
      # host name.
      #
      #     bucket = s3.bucket('my.bucket.com', virtual_host: true)
      #     bucket.url
      #     #=> "http://my.bucket.com"
      #
      # @option options [Boolean] :virtual_host (false) When `true`,
      #   the bucket name will be used as the host name. This is useful
      #   when you have a CNAME configured for this bucket.
      #
      # @return [String] the URL for this bucket.
      def url(options = {})
        if options[:virtual_host]
          "http://#{name}"
        else
          s3_bucket_url
        end
      end

      # Creates a {PresignedPost} that makes it easy to upload a file from
      # a web browser direct to Amazon S3 using an HTML post form with
      # a file field.
      #
      # See the {PresignedPost} documentation for more information.
      # @note You must specify `:key` or `:key_starts_with`. All other options
      #   are optional.
      # @option (see PresignedPost#initialize)
      # @return [PresignedPost]
      # @see PresignedPost
      def presigned_post(options = {})
        PresignedPost.new(
          client.config.credentials,
          client.config.region,
          name,
          options)
      end

      # @api private
      def load
        @data = client.list_buckets.buckets.find { |b| b.name == name }
        raise "unable to load bucket #{name}" if @data.nil?
        self
      end

      private

      def s3_bucket_url
        url = client.config.endpoint.dup
        if bucket_as_hostname?(url.scheme == 'https')
          url.host = "#{name}.#{url.host}"
        else
          url.path += '/' unless url.path[-1] == '/'
          url.path += Seahorse::Util.uri_escape(name)
        end
        url.to_s
      end

      def bucket_as_hostname?(https)
        Plugins::S3BucketDns.dns_compatible?(name, https) &&
        !client.config.force_path_style
      end

    end
  end
end
