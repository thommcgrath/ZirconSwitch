#tag Class
Protected Class ZirconSwitch
Inherits ArtisanKit.Control
	#tag Event
		Sub AnimationStep(Key As String, Value As Double, Finished As Boolean)
		  Select Case Key
		  Case "PressedOpacity"
		    Self.PressedOpacity = Value
		    Self.Invalidate
		  Case "Position"
		    Self.Position = Value
		    Self.Invalidate
		  Else
		    RaiseEvent AnimationStep(Key, Value, Finished)
		  End Select
		End Sub
	#tag EndEvent

	#tag Event
		Function KeyDown(Key As String) As Boolean
		  If KeyDown(Key) Then
		    Return True
		  End If
		  
		  Var KeyCode As Integer = Asc(Key)
		  Select Case KeyCode
		  Case &h0A, &h0D, &h20
		    Self.Value = Not Self.Value
		  Case &h1C
		    Self.Value = False
		  Case &h1D
		    Self.Value = True
		  Else
		    Return False
		  End Select
		  
		  Return True
		End Function
	#tag EndEvent

	#tag Event
		Function MouseDown(X As Integer, Y As Integer) As Boolean
		  #pragma Unused Y
		  
		  Self.CancelAnimation("PressedOpacity")
		  
		  Var Left As Integer = Self.ActualControlLeft(Self.Width)
		  Var Right As Integer = Left + Self.ActualControlWidth
		  If X >= Left And X <= Right Then
		    Self.PressedOpacity = 1.0
		    Self.MouseDownX = X
		    Self.Invalidate()
		    Self.ManualDrag = False
		    Return True
		  End If
		End Function
	#tag EndEvent

	#tag Event
		Sub MouseDrag(X As Integer, Y As Integer)
		  #pragma Unused Y
		  
		  If Not Self.ManualDrag Then
		    If X >= Self.MouseDownX + 5 Or X <= Self.MouseDownX - 5 Then
		      Self.ManualDrag = True
		    End If
		  End If
		  If Self.ManualDrag Then
		    Var DeltaX As Integer = X - Self.MouseDownX
		    Var ThumbRect As Rect = Self.ThumbRect
		    Var XBefore As Integer = ThumbRect.Left
		    ThumbRect.Offset(DeltaX, 0)
		    Self.ThumbRect = ThumbRect
		    ThumbRect = Self.ThumbRect // Load it again to figure out what impact DeltaX actually had
		    Var XAfter As Integer = ThumbRect.Left
		    Self.MouseDownX = Self.MouseDownX + (XAfter - XBefore)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseUp(X As Integer, Y As Integer)
		  #pragma Unused X
		  #pragma Unused Y
		  
		  Self.StartAnimation("PressedOpacity", Self.PressedOpacity, 0.0, 0.3)
		  
		  If Self.ManualDrag Then
		    Self.Value = Self.Position > 0.5
		  Else
		    Self.Value = Not Self.Value
		  End If
		  Self.Invalidate
		End Sub
	#tag EndEvent

	#tag Event
		Sub Open()
		  Self.Ready = True
		  RaiseEvent Open
		  Self.mOpenFinished = True
		End Sub
	#tag EndEvent

	#tag Event
		Sub Paint(G As Graphics, Areas() As Xojo.Rect, Highlighted As Boolean)
		  #pragma Unused Areas
		  
		  // Give an opportunity for the control to draw a custom background
		  RaiseEvent Paint(G)
		  
		  // Need to determine the width of the control
		  Var ControlWidth As Integer = Self.ActualControlWidth
		  If ControlWidth = 0 Then
		    Return
		  End If
		  
		  Var ThumbRect As Rect = Self.ThumbRect
		  Var GraphicWidth As Integer = ControlWidth
		  Var GraphicHeight As Integer = G.Height
		  Var OnColor As Color = Self.LeftSideColor.AtOpacity(Self.Position)
		  Var OffColor As Color = Self.RightSideColor
		  If Not Highlighted Then
		    OnColor = HSV(OnColor.Hue, 0, OnColor.Value, OnColor.Alpha)
		    OffColor = HSV(OffColor.Hue, 0, OffColor.Value, OffColor.Alpha)
		  End If
		  
		  Var OnTextColor As Color = If(ArtisanKit.ColorIsBright(OnColor), &c00000040, &cFFFFFF)
		  Var OffTextColor As Color = If(ArtisanKit.ColorIsBright(OffColor), &c00000040, &cFFFFFF)
		  
		  Var Full As Picture = G.NewPicture(GraphicWidth, GraphicHeight)
		  If Self.Position < 1.0 Then
		    Full.Graphics.DrawingColor = OffColor
		    Full.Graphics.FillRectangle(0, 0, GraphicWidth, GraphicHeight)
		  End If
		  If Self.Position > 0.0 Then
		    Full.Graphics.DrawingColor = OnColor
		    Full.Graphics.FillRectangle(0, 0, GraphicWidth, GraphicHeight)
		  End If
		  
		  Var BorderMask As Picture = G.NewPicture(GraphicWidth, GraphicHeight)
		  BorderMask.Graphics.DrawingColor = &cD4D4D4
		  BorderMask.Graphics.FillRectangle(0, 0, GraphicWidth, GraphicHeight)
		  BorderMask.Graphics.DrawingColor = &cFFFFFF
		  BorderMask.Graphics.FillRoundRectangle(1, 1, GraphicWidth - 2, GraphicHeight - 2, GraphicHeight - 2, GraphicHeight - 2)
		  
		  Var Border As Picture = G.NewPicture(GraphicWidth, GraphicHeight)
		  Border.Graphics.DrawingColor = &c000000
		  Border.Graphics.FillRectangle(0, 0, GraphicWidth, GraphicHeight)
		  Border.ApplyMask(BorderMask)
		  
		  #if XojoVersion >= 2020.02
		    Var Shadow As New ShadowBrush
		    Shadow.BlurAmount = 3
		    Shadow.Offset = New Point(0, 1)
		    Shadow.ShadowColor = &c00000080
		    Full.Graphics.ShadowBrush = Shadow
		  #endif
		  
		  Full.Graphics.DrawPicture(Border, 0, 0)
		  Full.Graphics.DrawingColor = &cFFFFFF
		  Full.Graphics.FillOval(ThumbRect.Left, ThumbRect.Top, ThumbRect.Width, ThumbRect.Height)
		  
		  Self.SetupFont(Full.Graphics)
		  
		  Var OnCaptionSpace As Integer = ControlWidth - ((ThumbRect.Width + (Self.ThumbPadding * 2)) * 1.5)
		  Var OnCaptionRect As New Rect(ThumbRect.Left - (OnCaptionSpace + Self.ThumbPadding), 1, OnCaptionSpace, GraphicHeight - 2)
		  #if XojoVersion >= 2020.02
		    Var OnCaptionWidth As Integer = Min(Ceiling(Full.Graphics.TextWidth(Self.LeftSideCaption)), OnCaptionRect.Width)
		  #else
		    Var OnCaptionWidth As Integer = Min(Ceil(Full.Graphics.TextWidth(Self.LeftSideCaption)), OnCaptionRect.Width)
		  #endif
		  Var OnCaptionLeft As Integer = OnCaptionRect.Left + Floor((OnCaptionRect.Width - OnCaptionWidth) / 2)
		  Var OnCaptionBaseline As Integer = OnCaptionRect.Top + Round((OnCaptionRect.Height / 2) + (Full.Graphics.CapHeight / 2))
		  
		  Var OffCaptionSpace As Integer = ControlWidth - ((ThumbRect.Width + (Self.ThumbPadding * 2)) * 1.5)
		  Var OffCaptionRect As New Rect(ThumbRect.Right + Self.ThumbPadding, 1, OffCaptionSpace, GraphicHeight - 2)
		  #if XojoVersion >= 2020.02
		    Var OffCaptionWidth As Integer = Min(Ceiling(Full.Graphics.TextWidth(Self.RightSideCaption)), OffCaptionRect.Width)
		  #else
		    Var OffCaptionWidth As Integer = Min(Ceil(Full.Graphics.TextWidth(Self.RightSideCaption)), OffCaptionRect.Width)
		  #endif
		  Var OffCaptionLeft As Integer = OffCaptionRect.Left + Floor((OffCaptionRect.Width - OffCaptionWidth) / 2)
		  Var OffCaptionBaseline As Integer = OffCaptionRect.Top + Round((OffCaptionRect.Height / 2) + (Full.Graphics.CapHeight / 2))
		  
		  Full.Graphics.DrawingColor = OnTextColor
		  Full.Graphics.DrawText(Self.LeftSideCaption, OnCaptionLeft, OnCaptionBaseline, OnCaptionRect.Width, True)
		  Full.Graphics.DrawingColor = OffTextColor
		  Full.Graphics.DrawText(Self.RightSideCaption, OffCaptionLeft, OffCaptionBaseline, OffCaptionRect.Width, True)
		  
		  #if XojoVersion >= 2020.02
		    Full.Graphics.ShadowBrush = Nil
		  #endif
		  
		  If Self.PressedOpacity > 0.0 Then
		    Var PressedColor As Color = &c000000D4
		    Full.Graphics.DrawingColor = PressedColor.AtOpacity(Self.PressedOpacity)
		    Full.Graphics.FillRectangle(0, 0, GraphicWidth, GraphicHeight)
		  End If
		  
		  Var White As Picture = G.NewPicture(GraphicWidth, GraphicHeight)
		  White.Graphics.DrawingColor = &cFFFFFF
		  White.Graphics.FillRectangle(0, 0, GraphicWidth, GraphicHeight)
		  
		  Var Mask As Picture = G.NewPicture(GraphicWidth, GraphicHeight)
		  Mask.Graphics.DrawingColor = &c000000
		  Mask.Graphics.FillRectangle(0, 0, GraphicWidth, GraphicHeight)
		  Mask.Graphics.DrawingColor = &cFFFFFF
		  Mask.Graphics.FillRoundRectangle(0, 0, GraphicWidth, GraphicHeight, GraphicHeight, GraphicHeight)
		  White.ApplyMask(Mask)
		  
		  Var FullMask As Picture = Full.CopyMask
		  FullMask.Graphics.ScaleX = G.ScaleX
		  FullMask.Graphics.ScaleY = G.ScaleY
		  FullMask.Graphics.DrawPicture(White, 0, 0)
		  Full.ApplyMask(FullMask)
		  
		  If Self.HasFocus Then
		    ArtisanKit.BeginFocusRing()
		  End If
		  G.DrawPicture(Full, Self.ActualControlLeft(G.Width), 0)
		  If Self.HasFocus Then
		    ArtisanKit.EndFocusRing()
		  End If
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Function ActualControlLeft(Width As Integer) As Integer
		  Select Case Self.mAlign
		  Case Self.AlignLeft
		    Return 0
		  Case Self.AlignCenter
		    Return Floor((Width - Self.ActualControlWidth) / 2)
		  Case Self.AlignRight
		    Return Width - Self.ActualControlWidth
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ActualControlWidth() As Integer
		  Var ControlWidth As Integer
		  If Self.ControlWidth = Self.ControlWidthAuto Then
		    Var Metrics As New Picture(2, 2, 32)
		    Self.SetupFont(Metrics.Graphics)
		    
		    Var LeftSideWidth As Double = Metrics.Graphics.TextWidth(Self.LeftSideCaption)
		    Var RightSideWidth As Double = Metrics.Graphics.TextWidth(Self.RightSideCaption)
		    Var LargestSideWidth As Double = Max(LeftSideWidth, RightSideWidth)
		    #if XojoVersion >= 2020.02
		      LargestSideWidth = Ceiling(LargestSideWidth)
		    #else
		      LargestSideWidth = Ceil(LargestSideWidth)
		    #endif
		    
		    ControlWidth = LargestSideWidth + (Self.Height * 1.5)
		  Else
		    ControlWidth = Self.ControlWidth
		  End If
		  
		  Return Min(Max(ControlWidth, Self.Height * 2), Self.Width)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetupFont(G As Graphics)
		  If Self.Height >= 20 Then
		    #if TargetWin32 or TargetLinux
		      G.FontSize = 10
		    #else
		      G.FontSize = 13.5
		    #endif
		  ElseIf Self.Height >= 16 Then
		    #if TargetWin32 Or TargetLinux
		      G.FontSize = 8.5
		    #else
		      G.FontSize = 10.8
		    #endif
		  Else
		    #if TargetWin32 Or TargetLinux
		      G.FontSize = 6
		    #else
		      G.FontSize = 8.1
		    #endif
		  End If
		  
		  G.FontName = "System"
		  G.FontUnit = FontUnits.Point
		  G.Bold = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ThumbRect() As Rect
		  Var ThumbWidth As Integer = Self.Height - (Self.ThumbPadding * 2)
		  Var ThumbHeight As Integer = ThumbWidth
		  Var ThumbMinX As Integer = Self.ThumbPadding
		  Var ThumbMaxX As Integer = Self.ActualControlWidth - (Self.ThumbPadding + ThumbWidth)
		  Var ThumbRange As Integer = ThumbMaxX - ThumbMinX
		  
		  Return New Rect(ThumbMinX + Round(ThumbRange * Self.Position), Self.ThumbPadding, ThumbWidth, ThumbHeight)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ThumbRect(Assigns NewRect As Rect)
		  // We're really only going to take the left position
		  
		  Var ThumbWidth As Integer = Self.Height - (Self.ThumbPadding * 2)
		  Var ThumbMinX As Integer = Self.ThumbPadding
		  Var ThumbMaxX As Integer = Self.ActualControlWidth - ((Self.ThumbPadding * 2) + ThumbWidth)
		  Var ThumbRange As Integer = ThumbMaxX - ThumbMinX
		  
		  Self.Position = Max(Min((NewRect.Left - ThumbMinX) / ThumbRange, 1.0), 0.0)
		  Self.Invalidate
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Action()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event AnimationStep(Key As String, Value As Double, Finished As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event KeyDown(Key As String) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Open()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Paint(G As Graphics)
	#tag EndHook


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mAlign
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Self.mAlign = Min(Max(Value, Self.AlignLeft), Self.AlignRight)
			  Self.Invalidate
			End Set
		#tag EndSetter
		Align As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.Height
			End Get
		#tag EndGetter
		Attributes( Deprecated ) ControlHeight As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Select Case Self.Height
			  Case 20
			    Return 0
			  Case 16
			    Return 1
			  Case 12
			    Return 2
			  Else
			    Return -1
			  End Select
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  #Pragma Unused Value
			  
			  // Do nothing
			End Set
		#tag EndSetter
		Attributes( Deprecated ) ControlSize As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mControlWidth
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Self.mControlWidth = Value Then
			    Return
			  End If
			  
			  Self.mControlWidth = Value
			  Self.Invalidate
			End Set
		#tag EndSetter
		ControlWidth As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mLeftSideCaption
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Self.mLeftSideCaption = Value
			  Self.Invalidate
			  
			  Var Animated As Boolean = Self.Animated
			  Self.Animated = False
			  Self.State = Self.State
			  Self.Animated = Animated
			End Set
		#tag EndSetter
		LeftSideCaption As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mLeftSideColor
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Self.mLeftSideColor= Value
			  Self.Invalidate
			End Set
		#tag EndSetter
		LeftSideColor As Color
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mAlign As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private ManualDrag As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mControlWidth As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLeftSideCaption As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLeftSideColor As Color
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOpenFinished As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private MouseDownX As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRightSideCaption As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRightSideColor As Color
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mState As Integer = 1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Position As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private PressedOpacity As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Ready As Boolean
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mRightSideCaption
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Self.mRightSideCaption = Value
			  Self.Invalidate
			  
			  Var Animated As Boolean = Self.Animated
			  Self.Animated = False
			  Self.State = Self.State
			  Self.Animated = Animated
			End Set
		#tag EndSetter
		RightSideCaption As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mRightSideColor
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Self.mRightSideColor= Value
			  Self.Invalidate
			End Set
		#tag EndSetter
		RightSideColor As Color
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mState
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not Self.Ready Then
			    Return
			  End If
			  
			  Value = Min(Max(Value, StateIndeterminate), StateOn)
			  
			  Var TargetPosition As Double
			  Select Case Value
			  Case StateIndeterminate
			    TargetPosition = 0.5
			  Case StateOff
			    TargetPosition = 0.0
			  Case StateOn
			    TargetPosition = 1.0
			  End Select
			  
			  Self.StartAnimation("Position", Self.Position, TargetPosition, 0.15)
			  
			  If Self.mState <> Value Then
			    Self.mState = Value
			    RaiseEvent Action
			    Self.Invalidate
			  End If
			End Set
		#tag EndSetter
		State As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mState = StateOn
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Self.Ready Then
			    If Value Then
			      Self.State = StateOn
			    Else
			      Self.State = StateOff
			    End If
			  Else
			    If Value Then
			      Self.Position = 1.0
			      Self.mState = StateOn
			    Else
			      Self.Position = 0.0
			      Self.mState = StateOff
			    End If
			  End If
			End Set
		#tag EndSetter
		Value As Boolean
	#tag EndComputedProperty


	#tag Constant, Name = AlignCenter, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = AlignLeft, Type = Double, Dynamic = False, Default = \"0", Scope = Public
	#tag EndConstant

	#tag Constant, Name = AlignRight, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ControlWidthAuto, Type = Double, Dynamic = False, Default = \"-1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = PI, Type = Double, Dynamic = False, Default = \"3.14159265358979323846264338327950", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Revision, Type = Double, Dynamic = False, Default = \"4", Scope = Public
	#tag EndConstant

	#tag Constant, Name = SizeMini, Type = Double, Dynamic = False, Default = \"2", Scope = Public, Attributes = \"Deprecated"
	#tag EndConstant

	#tag Constant, Name = SizeNormal, Type = Double, Dynamic = False, Default = \"0", Scope = Public, Attributes = \"Deprecated"
	#tag EndConstant

	#tag Constant, Name = SizeSmall, Type = Double, Dynamic = False, Default = \"1", Scope = Public, Attributes = \"Deprecated"
	#tag EndConstant

	#tag Constant, Name = StateIndeterminate, Type = Double, Dynamic = False, Default = \"-1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = StateOff, Type = Double, Dynamic = False, Default = \"0", Scope = Public
	#tag EndConstant

	#tag Constant, Name = StateOn, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ThumbPadding, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Animated"
			Visible=false
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowAutoDeactivate"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Tooltip"
			Visible=true
			Group="Appearance"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowFocusRing"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowFocus"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowTabs"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="NeedsFullKeyboardAccessForFocus"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Align"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType="Enum"
			#tag EnumValues
				"0 - Left"
				"1 - Center"
				"2 - Right"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Backdrop"
			Visible=false
			Group="Appearance"
			InitialValue=""
			Type="Picture"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="ControlWidth"
			Visible=true
			Group="Behavior"
			InitialValue="-1"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="DoubleBuffer"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Enabled"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="HasFocus"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Height"
			Visible=true
			Group="Position"
			InitialValue="100"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="InitialParent"
			Visible=false
			Group=""
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LeftSideCaption"
			Visible=true
			Group="Behavior"
			InitialValue="On"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LeftSideColor"
			Visible=true
			Group="Behavior"
			InitialValue="&c177DF2"
			Type="Color"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockBottom"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockLeft"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockRight"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockTop"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="RightSideCaption"
			Visible=true
			Group="Behavior"
			InitialValue="Off"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RightSideColor"
			Visible=true
			Group="Behavior"
			InitialValue="&cEEEEEE"
			Type="Color"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="ScrollSpeed"
			Visible=false
			Group="Behavior"
			InitialValue="20"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="State"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType="Enum"
			#tag EnumValues
				"0 - Off"
				"1 - On"
				" - 1"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabIndex"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabPanelIndex"
			Visible=false
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabStop"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Transparent"
			Visible=true
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Value"
			Visible=true
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Visible"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Visible=true
			Group="Position"
			InitialValue="100"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
