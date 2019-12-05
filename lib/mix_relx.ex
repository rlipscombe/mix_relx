defmodule Mix.Tasks.Relx do
  use Mix.Task

  @recursive true

  @impl true
  def run(_args) do
    Mix.Task.run("loadpaths")

    if Mix.Utils.stale?(["relx.config.src"], ["relx.config"]) do
      Mix.shell().print_app()

      config = Mix.Project.config()
      vsn = config[:version]
      assigns = [vsn: vsn]

      Mix.Generator.copy_template(
        "relx.config.src",
        "relx.config",
        assigns,
        force: true,
        quiet: true
      )
    end

    # TODO: How do we detect that the release is up-to-date? Is it important?
    if File.exists?("relx.config") do
      Mix.shell().print_app()

      # Assumes that relx is in PATH
      Mix.Tasks.Cmd.run(["relx" | relx_args(Mix.env())])
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
end
