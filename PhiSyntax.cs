using Godot;
using PhiBasicTranslator.ParseEngine;
using PhiBasicTranslator.Structure;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class PhiSyntax : SyntaxHighlighter
{
	private List<Godot.Collections.Dictionary> ColorDict = new List<Godot.Collections.Dictionary>();

	Color[] clrs = 
	{
			Colors.White,  // None                                        None, 
			Colors.Green,                     // MultiComment,            MultiComment, 
			Colors.Green,                     // Comment,                 Comment, 
			Colors.Red, // String,                                        String, 
			Colors.Gray,                     // AsmClassStart,            AsmClassStart, 
			Colors.DarkGray,                  // ArmClassStart,           ArmClassStart,
			Colors.Aqua,                 // PhiClassStart,            PhiClassStart, 
			Colors.Aqua,// Curly,                                     Curly, 
			Colors.Blue,// Square,                                    Square, 
			Colors.Blue,                     // Parenthesis,          Parenthesis, 
			Colors.Magenta,                     // Colon,             Colon, 
			Colors.Magenta,                         //                SemiColon,
			Colors.DarkCyan,                     // ClassName,            ClassName, 
			Colors.DarkCyan,// ClassInherit,                              ClassInherit, 
			Colors.DarkCyan,// VariableName                               VariableName,
			Colors.Blue, // VariableType                              VariableType,
			Colors.Tan,                                 //             VariableValue,
			Colors.Blue,                               //             MethodOpen,
			Colors.Blue,                               //             MethodClose,
			Colors.Magenta,                            //             MethodSet,
			Colors.Blue,                               //             MethodEnd,
			Colors.Magenta,                            //             MethodReturn,
			Colors.DarkCyan,                               //             MethodName
			Colors.Cyan,                                   //             Instruct
			Colors.Red,
			Colors.Red,
			Colors.Blue,
			Colors.Tan,
			Colors.CadetBlue,
			Colors.AliceBlue,
			Colors.Red,
			Colors.Blue,
			Colors.Tan,
			Colors.CadetBlue,	
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue,
			Colors.AliceBlue
		};
	public override Godot.Collections.Dictionary _GetLineSyntaxHighlighting(int line)
	{
		if(ColorDict.Count > line)
		{
			return ColorDict[line];
		}
		else
		{
			return ColorDict.FirstOrDefault();
		}
	}

	public void SetColor(Inside label, Color c)
	{
		int bl = (int)label;

		if(clrs.Length > bl)
		{
			clrs[bl] = c;
		}
	}

	public int GetLineCount(string content)
	{
		int ln = 0;

		for(int i = 0; i < content.Length; i++)
		{
			if(content[i] == '\n')
			{
				ln++;
			}
		}

		return ln;
	}
	public PhiCoord GetLineForIndex(int index, string content)
	{
		int ln = 0;
		int nx = 0;

		for(int i = 0; i < content.Length; i++)
		{
			if(i < index)
			{
				nx++;

				if(content[i] == '\n')
				{
					
					ln++;
					nx = 0;
				}
			}
			else
			{
				break;
			}
		}

		return new PhiCoord(nx, ln);
	}
	public void InterpretPhi(string content)
	{
		if(content != null)
		{
			if(content.Length > 0)
			{
				ContentProfile prf = ParseUtilities.ProfileContent(content);
				
				Inside inside = Inside.None;
				Inside lastIn = Inside.None;

				PhiCoord crd = GetLineForIndex(0, content);
				int len = GetLineCount(content);

				List<Godot.Collections.Dictionary> dict = new Godot.Collections.Dictionary[len + 1].ToList();

				Color lastColor = Colors.White;
				
				for(int i = 0; i < prf.ContentInside.Length; i++)
				{
					inside = prf.ContentInside[i];

					if(inside != lastIn)
					{
						int c = (int)inside;

						crd = GetLineForIndex(i, content);

						if(dict[crd.line] == null)
						{
							dict[crd.line] = new Godot.Collections.Dictionary();
						}

						dict[crd.line].Add(crd.index, new Godot.Collections.Dictionary{{"color", clrs[c]}});
					}

					lastIn = inside;
				}

				if(dict.Count > 0)
				{
					ColorDict.Clear();
					ColorDict = dict;
				}
			}
		}
	}

	public class PhiCoord
	{
		public int index = -1;
		public int line = -1;
		public PhiCoord(int i, int ln)
		{
			index = i;
			line = ln;
		}
	}
}
