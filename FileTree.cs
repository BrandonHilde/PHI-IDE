using Godot;
using System;
using System.IO;

public partial class FileTree : Tree
{
	string rootFolder = "code";
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		string[] files = Directory.GetFiles(rootFolder);

		TreeItem root = CreateItem();
		root.SetText(0, rootFolder);

		foreach(string fil in files)
		{
			var f = CreateItem();

			string nme = Path.GetFileName(fil);
			f.SetText(0, nme);
		}
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	public void _on_item_selected()
	{
	 	TreeItem itm = GetSelected();

		if(File.Exists(rootFolder +"\\" + itm.GetText(0)))
		{
			CodeEdit code = GetNode<CodeEdit>("/root/Control/HSplitContainer/VSplitContainer/Control/CodeEdit");

			code.Text = File.ReadAllText(rootFolder +"\\" + itm.GetText(0));
			code.refresh();
			code.selectedFile = rootFolder +"\\" + itm.GetText(0);
		}
	}
}
