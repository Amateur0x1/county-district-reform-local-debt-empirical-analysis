import click
import subprocess

@click.group()
def cli():
    pass

@cli.command()
def run():
    """运行 index.py 主程序"""
    click.echo("Running index.py...")
    subprocess.run(['python', 'projects/main.py'])

if __name__ == '__main__':
    cli()