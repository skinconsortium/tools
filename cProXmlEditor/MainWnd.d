/*
	Generated by Entice Designer
	Entice Designer written by Christopher E. Miller
	www.dprogramming.com/entice.php
*/
module MainWnd;

import global;

import config;
import about;
import xmlio;

import dfl.all;

import paneltree.PanelNode;
import paneltree.PanelTree;

import pages.AppearancePanel;
import pages.ColorsPanel;
import pages.test;
import pages.Skinfo;

import tango.io.FilePath;
import tango.util.PathUtil;

class MainWnd: dfl.form.Form
{
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.panel.Panel panel3;
	dfl.button.Button saveBtn;
	dfl.label.Label statusText;
	//~Entice Designer variables end here.
	
	PanelTree myTree;
	MenuItem recentProjects;
	
	private import dfl.internal.dlib;
	private import dfl.control, dfl.internal.winapi, dfl.event, dfl.drawing;
	private import dfl.application, dfl.base, dfl.internal.utf;
	private import dfl.collections;
	
	private:
	bool viewingTemplate;
	char[] currentPath;
	
	this()
	{
		initializeMainWnd();
		initializeMenu();
		initializePanelTree();
	
		dockPadding.all = PADDING;
		panel3.dockPadding.top = PADDING;		
		icon = Application.resources.getIcon(ID_ICON);
		saveBtn.click ~= &fileSave;
		
		if (ConfigFile.getValue("windowPosX", int.min) != int.min)
		{
			startPosition = dfl.all.FormStartPosition.MANUAL;
			left = ConfigFile.getValue("windowPosX", 0);
			top = ConfigFile.getValue("windowPosY", 0);
		}
			
		// load base template files
		fileNew(null,null);
	}
	
	override protected void onClosing(CancelEventArgs cea)
	{
		ConfigFile.setValue("windowPosX", left);
		ConfigFile.setValue("windowPosY", top);
	}
	
	private void initializePanelTree()
	{
		myTree = new PanelTree(120, 10);
		myTree.name = "panelTree";
		myTree.dock = dfl.control.DockStyle.FILL;
		myTree.parent = this;
		
		XmlIO.get.linkPanelTree(&myTree);

		PanelNode skinXmlRoot = new PanelNode("skin.xml", "Skin Definition File", new Skinfo);
		myTree.addNode(skinXmlRoot);
		
		PanelNode flexXmlRoot = new PanelNode("flex.xml", "Appearance", new AppearancePanel);
		myTree.addNode(flexXmlRoot);
		myTree.addNode(new PanelNode("test", "Test", new TestPanel), flexXmlRoot);
		
		PanelNode colorsXmlRoot = new PanelNode("colors.xml", "Skin Colors", new ColorsPanel);
		myTree.addNode(colorsXmlRoot);

	}

	private void initializeMenu()
	{
		MenuItem mmenu;
		MenuItem mi;
		
		this.menu = new MainMenu;
		
		/// File ///
		with (mmenu = new MenuItem)
		{
			mmenu.text = "&File";
			this.menu.menuItems.add(mmenu);
			
			/// - New
			mi = new MenuItem;
			mi.text = "&New";
			mi.click ~= &fileNew;
			mmenu.menuItems.add(mi);
		
			/// - Open
			mi = new MenuItem;
			mi.text = "&Open...";
			mi.click ~= &fileOpen;
			mmenu.menuItems.add(mi);
		/+	
			/// - Open Recent
			with (mi = new MenuItem)
			{
				mi.text = "&Recent Projects";
				mmenu.menuItems.add(mi);
				mi.enabled = false;
				
				for (int i = 0; i < 5; i++)
				{
					auto path = ConfigFile.getValue("recentProject." ~ tango.text.convert.Integer.toString(i), null);
					if (!path)
						break;
						
					mi.enabled = true;
					
					mi = new MenuItem;
					mi.text = path;
					mi.click ~= &fileRecentProjects;
					mi.menuItems.add(mi);
				}
			}
		+/	
			// - Save
			mi = new MenuItem;
			mi.text = "&Save";
			mi.click ~= &fileSave;
			mmenu.menuItems.add(mi);
			
			// - Save As
			mi = new MenuItem;
			mi.text = "Save &As...";
			mi.click ~= &fileSaveAs;
			mmenu.menuItems.add(mi);			
			
			// ---
			mi = new MenuItem;
			mi.text = "-";
			mmenu.menuItems.add(mi);
			
			// - Exit
			mi = new MenuItem;
			mi.text = "E&xit";
			mi.click ~= &fileExit;
			mmenu.menuItems.add(mi);
		}
		
		/// About ///
		with (mmenu = new MenuItem)
		{
			mmenu = new MenuItem;
			mmenu.text = "&About";
			mmenu.click ~= &about;
			this.menu.menuItems.add(mmenu);
		}
	}
	
	/* handling menu actions */	
	private
	{
		void fileExit(Object sender, EventArgs ea)
		{
			Application.exitThread();
		}
		
		void fileRecentProjects(Object sender, EventArgs ea)
		{
			MenuItem mi = cast(MenuItem)sender;
			currentPath = mi.text;
			viewingTemplate = false;
			XmlIO.get.populateControls(currentPath);
			statusText.text = "editing: " ~ currentPath;
		}
		
		void fileOpen(Object sender, EventArgs ea)
		{
			try_again:
			FolderBrowserDialog fd = new FolderBrowserDialog();
			fd.selectedPath = ConfigFile.getValue("currentPath");
			fd.description = "Select a skin path. A valid skin path must contain:\nskin.xml";
			fd.showNewFolderButton = false;
			auto res = fd.showDialog(this);
			char[] normalizedPath = normalize(fd.selectedPath);
			tango.io.Stdout.Stdout(normalizedPath).newline;
			if (res !is dfl.base.DialogResult.OK)
				return;
				
			ConfigFile.setValue("currentPath", fd.selectedPath);
				
			int checkForFile(char[] filename)
			{
				FilePath file = (new FilePath(normalizedPath)).append(filename);
				if (!file.exists || file.isFolder)
				{
					auto ret = dfl.messagebox.msgBox(this, 
						filename ~ " has not been found in this directory!\nDo you want to select another directory instead?",
						"Error",
						dfl.messagebox.MsgBoxButtons.OK_CANCEL,
						dfl.messagebox.MsgBoxIcon.ERROR
					);
					
					if (ret == dfl.base.DialogResult.OK)
					{
						return 1;
					}
					return 2;
				}
				return 0;
			}
			
			foreach(node;myTree.getTree.nodes)
			{
				switch (checkForFile(node.text))
				{
					case 1: // try again;
						goto try_again;
						break;
					case 2: // cancel
						return;
						break;
					default: // no error
						break;
				}
			}
				
			for (int i = 4; i > -1; i--)
			{
				auto path = ConfigFile.getValue("recentProject." ~ tango.text.convert.Integer.toString(i), null);
				if (!path)
					continue;
				
				ConfigFile.setValue("recentProject." ~ tango.text.convert.Integer.toString(i+1), path);
			}

			ConfigFile.setValue("recentProject.0", fd.selectedPath);
			
			currentPath = normalizedPath;
			viewingTemplate = false;
			XmlIO.get.populateControls(currentPath);
			statusText.text = "editing: " ~ currentPath;
		}
		
		void fileNew(Object sender, EventArgs ea)
		{
			XmlIO.get.populateControls(TEMPLATES_PATH);
			viewingTemplate = true;
			statusText.text = "unsaved project";
		}
		
		void fileSave(Object sender, EventArgs ea)
		{
			if (viewingTemplate)
				fileSaveAs(sender, ea);
			else
				XmlIO.get.saveControls(currentPath);
		}

		void fileSaveAs(Object sender, EventArgs ea)
		{
			FolderBrowserDialog fd = new FolderBrowserDialog();
			fd.selectedPath = ConfigFile.getValue("currentPath");
			fd.description = "Select a path where you want to save this project.\nAttention: Existing skin files will be overwritten!";
			fd.showNewFolderButton = true;
			auto res = fd.showDialog(this);
			char[] normalizedPath = normalize(fd.selectedPath);
			tango.io.Stdout.Stdout(normalizedPath).newline;
			if (res !is dfl.base.DialogResult.OK)
				return;
				
			ConfigFile.setValue("currentPath", fd.selectedPath);
			
			currentPath = normalizedPath;
			viewingTemplate = false;
			
			XmlIO.get.saveControls(currentPath);
			statusText.text = "editing: " ~ currentPath;
		}
		
		void about(Object sender, EventArgs ea)
		{
			About a = new About;
			a.showDialog(this);
		}		
	}

	private void initializeMainWnd()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.5.02 code begins here.
		//~DFL Form
		formBorderStyle = dfl.all.FormBorderStyle.FIXED_SINGLE;
		maximizeBox = false;
		startPosition = dfl.all.FormStartPosition.CENTER_SCREEN;
		text = "ClassicPro::Flex XML Editor";
		clientSize = dfl.all.Size(562, 430);
		//~DFL dfl.panel.Panel=panel3
		panel3 = new dfl.panel.Panel();
		panel3.name = "panel3";
		panel3.dock = dfl.all.DockStyle.BOTTOM;
		panel3.bounds = dfl.all.Rect(0, 402, 562, 28);
		panel3.parent = this;
		//~DFL dfl.button.Button=saveBtn
		saveBtn = new dfl.button.Button();
		saveBtn.name = "saveBtn";
		saveBtn.dock = dfl.all.DockStyle.LEFT;
		saveBtn.text = "Save";
		saveBtn.bounds = dfl.all.Rect(0, 0, 120, 28);
		saveBtn.parent = panel3;
		//~DFL dfl.label.Label=statusText
		statusText = new dfl.label.Label();
		statusText.name = "statusText";
		statusText.dock = dfl.all.DockStyle.FILL;
		statusText.text = "unsaved project";
		statusText.textAlign = dfl.all.ContentAlignment.MIDDLE_CENTER;
		statusText.useMnemonic = false;
		statusText.bounds = dfl.all.Rect(120, 0, 442, 28);
		statusText.parent = panel3;
		//~Entice Designer 0.8.5.02 code ends here.
	}
}

int main()
{
	int result = 0;
	
	try
	{
		Application.enableVisualStyles();
		
		//@  Other application initialization code here.
		Application.run(new MainWnd());
	}
	catch(Object o)
	{
		msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
		
		result = 1;
	}
	
	return result;
}

