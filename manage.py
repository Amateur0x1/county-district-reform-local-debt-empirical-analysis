import os
import subprocess
import click

root_dir = os.path.abspath(os.path.dirname(__file__))
path = os.path.join(root_dir, 'projects/main.py')

@click.group()
def cli():
    pass

@cli.command()
def run():
    """运行 main.py 主程序"""
    # 在根目录运行 main.py
    click.echo(f"Running from directory: {root_dir}")
    click.echo(f"Running {path}...")
    subprocess.run(['python', path], check=True, cwd=root_dir)

if __name__ == '__main__':
    cli()