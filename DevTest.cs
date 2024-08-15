using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using PhiBasicTranslator;
using System.Threading;
using System.Collections.Concurrent;
using System.Linq;
using System.Runtime.CompilerServices;

public partial class DevTest : Control
{
	ConcurrentQueue<string> logs = new ConcurrentQueue<string>();
	CodeEdit code = null;
	TextEdit edit = null;

	public string file = "code\\hello.phi";

	string assmblr = "";

	string value = "";
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		code = 	GetNode<CodeEdit>("HSplitContainer/VSplitContainer/Control/CodeEdit");
		edit = 	GetNode<TextEdit>("HSplitContainer/VSplitContainer/TextEdit");

		if(File.Exists(file))
		{
			code.Text = File.ReadAllText(file);
			code.refresh();
		}

		assmblr = CheckForAssembler();
	}

	public string CheckForAssembler()
	{
		return "FASM";
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if(logs.TryDequeue(out value))
		{
			edit.Text += value;
		}
	}

	public void _on_option_button_item_selected(int i)
	{
		if(i == 0) assmblr = "FASM";
		if(i == 1) assmblr = "NASM";
	}

	public void EnterCommand(string command)
	{
		string outvalue = "";

		new Thread(()=>
		{
			Thread.CurrentThread.IsBackground = true;
		
			Process cmd = new Process();
			cmd.StartInfo.FileName = "cmd.exe";

			cmd.StartInfo.RedirectStandardInput = true;
			cmd.StartInfo.RedirectStandardOutput = true;
			cmd.StartInfo.RedirectStandardError = true;
			cmd.StartInfo.CreateNoWindow = true;
			cmd.StartInfo.UseShellExecute = false;
			cmd.Start();

			cmd.StandardInput.WriteLine(command);
			
			cmd.StandardInput.WriteLine("exit");

			cmd.StandardInput.Flush();
			cmd.StandardInput.Close();
			cmd.WaitForExit();
			outvalue = cmd.StandardOutput.ReadToEnd();
			outvalue += cmd.StandardError.ReadToEnd();
			logs.Enqueue(outvalue);
			
		}).Start();

	}

	public void _on_play_pressed()
	{
		file = code.selectedFile;

		if(file.ToLower().EndsWith(".asm") || file.ToLower().EndsWith(".phi"))
		{
			File.WriteAllText(file, code.Text);

			logs.Enqueue("Saved File: " + file + "\r\n");

			string name = Path.GetFileNameWithoutExtension(file);

			string path = Path.GetDirectoryName(file);

			name = path + "\\" + name;

			if(file.ToLower().EndsWith(".phi"))
			{
				GD.Print(name);

				Translator translator = new Translator();

				List<string> linesASM = translator.TranslateFile(file);

				File.WriteAllLines(name + ".asm", linesASM);		

				logs.Enqueue("Saved File: " + name + ".asm" + "\r\n");

			}
			else if(file.ToLower().EndsWith(".asm"))
			{
				logs.Enqueue("Building Assembly: " + name + ".asm" + "\r\n");
			}

			if(assmblr == "FASM")
			{
				EnterCommand("fasm " + name + ".asm " + name + ".bin");
			}
			else if (assmblr == "NASM")
			{
				EnterCommand("nasm -f bin " + name + ".asm -o " + name + ".bin");
			}

			if(assmblr != "") EnterCommand("qemu-system-x86_64 -fda " + name + ".bin");
		}
	}
}
