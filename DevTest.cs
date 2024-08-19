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
using PhiBasicTranslator.Structure;

public partial class DevTest : Control
{
	ConcurrentQueue<string> logs = new ConcurrentQueue<string>();
	CodeEdit code = null;
	TextEdit edit = null;

	Tree tree = null;

	public string file = "code\\hello.phi";

	string assmblr = "";

	string value = "";
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		code = 	GetNode<CodeEdit>("HSplitContainer/VSplitContainer/Control/CodeEdit");
		edit = 	GetNode<TextEdit>("HSplitContainer/VSplitContainer/TextEdit");

		tree = GetNode<Tree>("HSplitContainer/Panel/Tree");

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

		GD.Print(command);

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

			List<string> files = new List<string>();

			if(file.ToLower().EndsWith(".phi"))
			{
				Translator translator = new Translator();

				PhiCodebase codebase = translator.TranslateFile(file);

				foreach(PhiClass cls in codebase.ClassList)
				{
					files.Add(path + "\\" + cls.Name);

					File.WriteAllLines( path + "\\" + cls.Name + ".asm", cls.translatedASM);
					logs.Enqueue("Saved File: " +  path + "\\" + cls.Name + ".asm" + "\r\n");
				}

				if(files.Count > 0)
				{

					List<byte> opsys = new List<byte>();

					for(int i = 0; i < files.Count; i++)
					{
						build(files[i]);

						if(i == 0)
						{
							if(File.Exists(files[i]  + ".bin"))
							{
								opsys = File.ReadAllBytes(files[i] + ".bin").ToList();
							}
						}

						if(i > 0)
						{
							if(File.Exists(files[i]  + ".bin"))
							{
								opsys = Combine(opsys, files[i] + ".bin");
							}
							//EnterCommand("type " + files[i-1] + ".bin " + files[i] + ".bin > " + files[0] + ".bin");
							//type %1.bin %2.bin > os.bin
						}
					}

					File.WriteAllBytes(path + "\\os.bin", opsys.ToArray());

					if(assmblr != "") EnterCommand("qemu-system-x86_64 -fda " + path + "\\os.bin");
				}

			}
			else if(file.ToLower().EndsWith(".asm"))
			{
				build(name);

				if(assmblr != "") EnterCommand("qemu-system-x86_64 -fda " + name + ".bin");
			}
		}

		((FileTree)tree).ShowFiles();
	}

	public void build(string name)
	{
		logs.Enqueue("Building Assembly: " + name + ".asm" + "\r\n");

		if(assmblr == "FASM")
		{
			EnterCommand("fasm " + name + ".asm " + name + ".bin");
		}
		else if (assmblr == "NASM")
		{
			EnterCommand("nasm -f bin " + name + ".asm -o " + name + ".bin");
		}	

		Thread.Sleep(50); // allow system to catch up because these are multi-threaded
	}

	public List<byte> Combine(List<byte> first, string f2)
	{
		byte[] fbt2 = File.ReadAllBytes(f2);

		first.AddRange(fbt2);

		return first;
	}
}
