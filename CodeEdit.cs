using Godot;
using System;
using PhiBasicTranslator.Structure;
using System.ComponentModel;

public partial class CodeEdit : Godot.CodeEdit
{
	PhiSyntax syntax = new PhiSyntax();

	public string selectedFile = "code\\hello.phi";

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		SyntaxHighlighter = syntax;

		syntax.SetColor(Inside.Comment, Colors.LawnGreen);
		syntax.SetColor(Inside.MultiComment, Colors.LawnGreen);
		syntax.SetColor(Inside.String, Colors.PaleVioletRed);

		syntax.SetColor(Inside.SemiColon, Colors.Aquamarine);
		syntax.SetColor(Inside.InstructClose, Colors.Aquamarine);
		syntax.SetColor(Inside.VariableEnd, Colors.Aquamarine);
		syntax.SetColor(Inside.Opperation, Colors.Aquamarine);

		syntax.SetColor(Inside.ArmClassStart, Colors.Aquamarine);
		syntax.SetColor(Inside.AsmClassStart, Colors.Aquamarine);
		syntax.SetColor(Inside.PhiClassStart, Colors.Aquamarine);

		syntax.SetColor(Inside.ClassClose, Colors.Aquamarine);
		syntax.SetColor(Inside.CurlyClose, Colors.Aquamarine);
		syntax.SetColor(Inside.CurlyOpen, Colors.Aquamarine);
		syntax.SetColor(Inside.SquareClose, Colors.Aquamarine);
		syntax.SetColor(Inside.SquareOpen, Colors.Aquamarine);
		syntax.SetColor(Inside.Conditonal, Colors.Aquamarine);
		syntax.SetColor(Inside.Colon, Colors.Aquamarine);
		syntax.SetColor(Inside.ParenthesisClose, Colors.Aquamarine);
		syntax.SetColor(Inside.ParenthesisOpen, Colors.Aquamarine);

		syntax.SetColor(Inside.Instruct, Colors.DarkCyan);
		syntax.SetColor(Inside.ClassName, Colors.DarkCyan);
		syntax.SetColor(Inside.VariableName, Colors.DarkCyan);
		syntax.SetColor(Inside.VariableValue, Colors.DarkCyan);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	public void _on_ready()
	{
		refresh();
	}

	public void refresh()
	{
		syntax.InterpretPhi(Text);
		syntax.ClearHighlightingCache();
		QueueRedraw();
	}
	public void _on_text_changed()
	{
		refresh();
	}
}
