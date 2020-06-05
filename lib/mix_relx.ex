defmodule Mix.Tasks.Relx do
  use Mix.Task

  @recursive true

  @impl true
  def run(_args) do
    Mix.Task.run("loadpaths")

    if File.exists?("relx.config.src") do
      Mix.shell().print_app()

      config = Mix.Project.config()
      vsn = config[:version]

      assigns = %{"RELEASE_VERSION" => vsn}
      envsubst("relx.config.src", "relx.config", fn key -> Map.get(assigns, key, nil) end)
    end

    if File.exists?("relx.config") do
      Mix.shell().print_app()

      # Assumes that relx is in PATH
      Mix.Tasks.Cmd.run(["relx" | relx_args(Mix.env())])

      # Symlink releases/current to releases/$RELEASE_VERSION
      symlink_current()
    end

    :ok
  end

  defp relx_args(:dev) do
    ["--dev-mode" | default_relx_args()]
  end

  defp relx_args(_), do: default_relx_args()

  defp default_relx_args do
    root_dir = Mix.Project.build_path()
    output_dir = Path.join(Mix.Project.build_path(), "rel")

    [
      "--config",
      "relx.config",
      "--root",
      root_dir,
      "--output-dir",
      output_dir
    ]
  end

  defp envsubst(source, destination, getenv) do
    content = File.read!(source)

    # Get a list of the ${variables} that need replacing.
    vars = Regex.scan(~R/\${(.+)}/U, content)

    f = fn [p, v], c ->
      case getenv.(v) do
        nil ->
          warn("#{source}: env var #{v} not found")
          c

        r ->
          String.replace(c, p, r)
      end
    end

    content = List.foldl(vars, content, f)

    File.write!(destination, content)
  end

  defp symlink_current do
    output_dir = Path.join(Mix.Project.build_path(), "rel")

    config = Mix.Project.config()
    app_name = config[:app]
    vsn = config[:version]
    current_rel = Path.join([output_dir, Atom.to_string(app_name), "releases", "current"])
    target = vsn
    _ = :file.make_symlink(current_rel, target)
  end

  defp warn(message) do
    Mix.shell().info([:yellow, message, :reset])
  end
end
