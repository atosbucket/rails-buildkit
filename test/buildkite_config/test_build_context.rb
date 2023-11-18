# frozen_string_literal: true

require "test_helper"
require "buildkite_config"

class TestBuildContext < TestCase
  def create_build_context
    Buildkite::Config::BuildContext.new("context")
  end

  def test_initializer
    sub = create_build_context
    assert_not_nil sub
  end

  def test_pipeline_name
    @before_buildkite_pipeline_name = ENV["BUILDKITE_PIPELINE_NAME"]
    ENV["BUILDKITE_PIPELINE_NAME"] = "test_pipeline_name"

    sub = create_build_context
    assert_equal "test_pipeline_name", sub.pipeline_name
  ensure
    ENV["BUILDKITE_PIPELINE_NAME"] = @before_buildkite_pipeline_name
  end

  def test_ci_env_buildkite
    @before_env_buildkite = ENV["BUILDKITE"]
    ENV["BUILDKITE"] = "true"

    sub = create_build_context
    assert sub.ci?
  ensure
    ENV["BUILDKITE"] = @before_env_buildkite
  end

  def test_ci_env_ci
    @before_env_ci = ENV["CI"]
    ENV["CI"] = "true"

    sub = create_build_context
    assert sub.ci?
  ensure
    ENV["CI"] = @before_env_ci
  end

  def test_rails_root
    sub = create_build_context
    sub.stub(:ci?, true) do
      sub.stub(:pipeline_name, "rails-ci") do
        assert_equal Pathname.new(Dir.pwd), sub.rails_root
      end
    end
  end

  def test_rails_root_not_ci
    sub = create_build_context
    sub.stub(:ci?, false) do
      assert_equal Pathname.new(Dir.pwd) + "tmp/rails", sub.rails_root
    end
  end

  def test_rails_root_not_pipeline
    sub = create_build_context
    sub.stub(:ci?, true) do
      sub.stub(:pipeline_name, "not-rails-ci") do
        assert_equal Pathname.new(Dir.pwd) + "tmp/rails", sub.rails_root
      end
    end
  end

  def test_rails_version
    sub = create_build_context
    sub.stub(:rails_version_file, "6.1.0.rc1") do
      assert_equal sub.rails_version, Gem::Version.new("6.1.0.rc1")
    end
  end

  def test_one_ruby
    sub = create_build_context
    rubies = [
      Buildkite::Config::RubyConfig.new(version: Gem::Version.new("3.3"), soft_fail: true),
      Buildkite::Config::RubyConfig.new(version: Gem::Version.new("3.2")),
      Buildkite::Config::RubyConfig.new(version: Gem::Version.new("2.7"))
    ]

    sub.stub(:rubies, rubies) do
      assert_equal sub.one_ruby, rubies[1]
    end
  end

  def test_bundler_1_x
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("4.2")) do
      assert_equal sub.bundler, "< 2"
    end
  end

  def test_bundler_2_2
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("5.1.4")) do
      assert_equal sub.bundler, "< 2.2.10"
    end
  end

  def test_rubygems_2_6
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("4.2")) do
      assert_equal sub.rubygems, "2.6.13"
    end
  end

  def test_rubygems_3_2
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("5.1.4")) do
      assert_equal sub.rubygems, "3.2.9"
    end
  end

  def test_max_ruby_2_4
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("4.2")) do
      assert_equal sub.max_ruby, Gem::Version.new("2.4")
    end
  end

  def test_max_ruby_2_5
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("5.1")) do
      assert_equal sub.max_ruby, Gem::Version.new("2.5")
    end
  end

  def test_max_ruby_2_6
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("5.2")) do
      assert_equal sub.max_ruby, Gem::Version.new("2.6")
    end
  end

  def test_max_ruby_2_7
    sub = create_build_context
    sub.stub(:rails_version, Gem::Version.new("6.0")) do
      assert_equal sub.max_ruby, Gem::Version.new("2.7")
    end
  end

  def test_docker_compose_plugin
    sub = create_build_context
    assert_equal sub.docker_compose_plugin, "docker-compose#v3.7.0"
  end

  def test_artifacts_plugin
    sub = create_build_context
    assert_equal sub.artifacts_plugin, "artifacts#v1.2.0"
  end

  def test_remote_image_base
    sub = create_build_context
    assert_equal "973266071021.dkr.ecr.us-east-1.amazonaws.com/builds", sub.remote_image_base
  end

  def test_remote_image_base_standard_queues
    sub = create_build_context

    sub.stub(:build_queue, "test_remote_image_base_standard_queues") do
      assert_equal "973266071021.dkr.ecr.us-east-1.amazonaws.com/test_remote_image_base_standard_queues-builds", sub.remote_image_base
    end
  end

  def test_image_base
    sub = create_build_context
    assert_equal "buildkite-config-base", sub.image_base
  end

  def test_image_base_without_env_docker_image
    @before_docker_image = ENV["DOCKER_IMAGE"]
    ENV["DOCKER_IMAGE"] = nil

    sub = create_build_context
    assert_equal sub.remote_image_base, sub.image_base
  ensure
    ENV["DOCKER_IMAGE"] = @before_docker_image
  end

  def test_build_id
    sub = create_build_context
    assert_equal "local", sub.build_id
  end

  def test_build_id_without_env_buildkite_build_id_and_with_env_build_id
    @before_build_id = ENV["BUILD_ID"]
    @before_buildkite_build_id = ENV["BUILDKITE_BUILD_ID"]
    ENV["BUILD_ID"] = "test_build_id_without_env_buildkite_build_id_and_with_env_build_id"
    ENV["BUILDKITE_BUILD_ID"] = nil

    sub = create_build_context
    assert_equal "test_build_id_without_env_buildkite_build_id_and_with_env_build_id", sub.build_id
  ensure
    ENV["BUILD_ID"] = @before_build_id
    ENV["BUILDKITE_BUILD_ID"] = @before_buildkite_build_id
  end

  def test_build_id_without_env
    @before_build_id = ENV["BUILD_ID"]
    @before_buildkite_build_id = ENV["BUILDKITE_BUILD_ID"]
    ENV["BUILD_ID"] = nil
    ENV["BUILDKITE_BUILD_ID"] = nil

    sub = create_build_context
    assert_equal "build_id", sub.build_id
  ensure
    ENV["BUILD_ID"] = @before_build_id
    ENV["BUILDKITE_BUILD_ID"] = @before_buildkite_build_id
  end

  def test_queue
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = "test_queue"

    sub = create_build_context
    assert_equal "test_queue", sub.queue
  ensure
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end

  def test_queue_with_standard_queues_default
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = "default"

    sub = create_build_context
    assert_nil sub.queue
  ensure
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end

  def test_queue_with_standard_queues_builder
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = "builder"

    sub = create_build_context
    assert_nil sub.queue
  ensure
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end

  def test_queue_with_standard_queues_nil
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = nil

    sub = create_build_context
    assert_nil sub.queue
  ensure
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end

  def test_build_queue_with_env
    @before_build_queue = ENV["BUILD_QUEUE"]
    ENV["BUILD_QUEUE"] = "test_build_queue_with_env"

    sub = create_build_context
    assert_equal "test_build_queue_with_env", sub.build_queue
  ensure
    ENV["BUILD_QUEUE"] = @before_build_queue
  end

  def test_build_queue_with_meta_data_queue
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = "test_build_queue_with_meta_data_queue"

    sub = create_build_context
    assert_equal "test_build_queue_with_meta_data_queue", sub.build_queue
  ensure
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end

  def test_build_queue_with_no_env
    @before_build_queue = ENV["BUILD_QUEUE"]
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["BUILD_QUEUE"] = nil
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = nil

    sub = create_build_context
    assert_equal "builder", sub.build_queue
  ensure
    ENV["BUILD_QUEUE"] = @before_build_queue
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end

  def test_run_queue_with_env
    @before_run_queue = ENV["RUN_QUEUE"]
    ENV["RUN_QUEUE"] = "test_run_queue_with_env"

    sub = create_build_context
    assert_equal "test_run_queue_with_env", sub.run_queue
  ensure
    ENV["RUN_QUEUE"] = @before_run_queue
  end

  def test_run_queue_with_meta_data_queue
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = "test_run_queue_with_meta_data_queue"

    sub = create_build_context
    assert_equal "test_run_queue_with_meta_data_queue", sub.run_queue
  ensure
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end

  def test_run_queue_with_no_env
    @before_run_queue = ENV["RUN_QUEUE"]
    @before_buildkite_agent_meta_data_queue = ENV["BUILDKITE_AGENT_META_DATA_QUEUE"]
    ENV["RUN_QUEUE"] = nil
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = nil

    sub = create_build_context
    assert_equal "default", sub.run_queue
  ensure
    ENV["RUN_QUEUE"] = @before_run_queue
    ENV["BUILDKITE_AGENT_META_DATA_QUEUE"] = @before_buildkite_agent_meta_data_queue
  end
end
