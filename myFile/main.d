/*
	Generated by Entice Designer
	Entice Designer written by Christopher E. Miller
	www.dprogramming.com/entice.php
*/

module main;


import controller.ModelController;
import model.XmlModel;
import about;
import global;

import dfl.all;
import com.skinconsortium.d.commons.ConfigFile;
import com.skinconsortium.d.dfl.MenuWindow;

import tango.io.FilePath;
import tango.net.Socket;
import UI = ui.handlers;
import tango.stdc.stdint;
import tango.text.Properties;
import model.StringUtils; // TODO CLEANUP

import com.skinconsortium.d.model.ModelContainer;

class Main: MenuWindow, IModelContainer
{
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.panel.Panel mainPanel;
	dfl.panel.Panel leftPane;
	dfl.listbox.ListBox lstItems;
	dfl.button.Button btnNew;
	dfl.splitter.Splitter poppler;
	dfl.panel.Panel rightPanel;
	dfl.textbox.TextBox txtTitle;
	dfl.panel.Panel panel1;
	dfl.textbox.TextBox txtContent;
	//~Entice Designer variables end here.
	
	private:
	XmlModel model;
	ModelController!(XmlModel) controller;

	this()
	{
		super();
		aboutWindow = new About;
		icon = Application.resources.getIcon(ID_ICON);
		controller = new ModelController!(XmlModel)(this);
		initializeMain();
		initApplication();
		
		//@  Other Main initialization code here.
		
		mainPanel.dockPadding.all = 6;

		//lstItems.selectedValueChanged ~= (ListControl lc, EventArgs ea){UI.onSelectionChanged(lc, ea);};
		lstItems.selectedValueChanged ~= &onSelectionChanged;
		lstItems.keyUp ~= &removeSelected;
		btnNew.click ~= &createNewEntry;
		txtTitle.lostFocus ~= &updateTitle;
		txtContent.lostFocus ~= &updateContent;
	}
	
	
	/** called on app startup */
	private public void initApplication()
	{
		controller.updateModel(new XmlModel(ConfigFile.getValue("lastOpenedFile", null)));
		poppler.splitPosition = ConfigFile.getValue("popplerPos", poppler.splitPosition);	
	}
	
	
	/** Called on window closed */
	override protected void saveWindowPosition()
	{
		updateAll();
		controller.saveModel();
		
		super.saveWindowPosition();
		ConfigFile.setValue("popplerPos", poppler.splitPosition);
		ConfigFile.setValue("lastOpenedFile", model.getFilename());
	}
	
	override protected void initializeMenu()
	{
		super.initializeMenu();
		
		MenuItem mmenu;
		MenuItem mi;
		
		/// Export ///
		with (mmenu = new MenuItem("&Export"))
		{
			// FIXME - HACK
			auto last = this.menu.menuItems[this.menu.menuItems.length-1];
			this.menu.menuItems.removeAt(this.menu.menuItems.length-1);
			
			//mmenu.index = 0;
			this.menu.menuItems.add(mmenu);
			
			// FIXME - HACK
			this.menu.menuItems.add(last);
			
			/// - Export to HTML
			mi = new MenuItem("Export to &HTML...");
			mi.click ~= &menuExportHTML;
			menuItems.add(mi);
		}
	}
	
	/// IModelContainer methods, do not call those methods from within this class.
	override public
	{
		/** sets the model */
		void setModel(IModel model)
		{
			//assert(is(typeof(model) == XmlModel));
			makeVirginControls();
			try
			{
				this.model = cast(XmlModel) model;
				lstItems.items.clear();
				lstItems.items.addRange(this.model.getFileEntries());
			}
			catch (Exception e) {}
		}	
		
		/** gets the model */
		IModel getModel()
		{
			return model;
		}
	}
	
	/// UI Handling via delegates
	public
	{
		void onSelectionChanged(ListControl lc = null, EventArgs ea = null)
		{
			if (lstItems.selectedIndex < 0)
				return;
			
			txtTitle.text = lstItems.selectedItem.toString;
			txtContent.text = model.getValue(txtTitle.text);			
			txtTitle.tag = new dfl.all.StringObject(txtTitle.text);
			
			txtTitle.enabled = true;
			txtContent.enabled = true;
		}
		
		void removeSelected(Control lc, KeyEventArgs ea)
		{
			int selIdx = lstItems.selectedIndex;
			if (selIdx < 0)
				return;
			
			if (ea.keyCode == Keys.DEL)
			{
				model.removeKey(lstItems.selectedItem.toString);
				lstItems.items.removeAt(lstItems.findStringExact(txtTitle.tag.toString));
				if (lstItems.items.length > 0)
				{
					lstItems.selectedIndex = selIdx;
					onSelectionChanged();
				}
				else
				{
					makeVirginControls();
				}
			}
		}
		
		void updateTitle(Control c = null, EventArgs ea = null)
		{
			if (txtTitle.tag is null)
				return;
			if (txtTitle.tag.toString != txtTitle.text)
			{
				lstItems.items.removeAt(lstItems.findStringExact(txtTitle.tag.toString)); // We need to delete and insert, since otherwise the sorted list won#t be updated!
				txtTitle.text = model.makeUnique(txtTitle.text);
				lstItems.items.add(txtTitle.text);
				model.removeKey(txtTitle.tag.toString);	
				model.setValue(txtTitle.text, txtContent.text);
				txtTitle.tag = new dfl.all.StringObject(txtTitle.text);
				lstItems.selectedItem = txtTitle.text;
			}
		}

		void updateContent(Control c = null, EventArgs ea = null)
		{
			if (txtTitle.tag is null)
				return;
			
			if (txtTitle.text != model.getValue(txtTitle.tag.toString))
				model.setValue(txtTitle.tag.toString, txtContent.text); // Better trust the tag here :P
		}
		
		void updateAll()
		{
			updateTitle();
			updateContent();
		}
		
		void createNewEntry(Object sender, EventArgs ea)
		{
			char[] myTag = model.makeUnique(".new entry");
			
			model.setValue(myTag, "");
			lstItems.items.add(myTag);
			lstItems.selectedItem = myTag;
			//we need to trigger this event now as well
			onSelectionChanged();
		}
		
		void makeVirginControls()
		{
			txtTitle.text = "";
			txtTitle.tag = null;
			txtContent.text = "";
			txtTitle.enabled = false;
			txtContent.enabled = false;
		}
	}
	
	/// Menu Handling
	override protected
	{
		void menuFileOpen(Object sender, EventArgs ea)
		{
			updateAll();
			controller.openModel();
		}
		
		void menuFileNew(Object sender, EventArgs ea)
		{
			updateAll();
			controller.newModel();
		}
		
		void menuFileSave(Object sender, EventArgs ea)
		{
			updateAll();
			controller.saveModel();
		}
		
		void menuFileSaveAs(Object sender, EventArgs ea)
		{
			updateAll();
			controller.saveModelAs();
		}

	}
	void menuExportHTML(Object sender, EventArgs ea)
	{
		auto fp = new tango.io.FilePath.FilePath("C:/export.html");
		bool existed = fp.exists;
		if (!existed)
		{
			fp.createFile;
		}
		
		auto file = new tango.io.File.File(fp.toString());
		auto doc = new tango.text.xml.Document.Document!(char);
		
		auto bodyE = doc.root.element(null, "html").element(null, "body");
			
		foreach(char[] key, char[] value; model.getMap())
		{
			bodyE.element(null, "h2", key);
			bodyE.element(null, "p", nlToBr!(char)(value));
		}
		
		auto print = new tango.text.xml.DocPrinter.DocPrinter!(char);
		file.write(cast(void[])print(doc));
	}
	
	/// Entice DFL Stuff
	private void initializeMain()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.6pre4 code begins here.
		//~DFL Form
		text = "myFile";
		//clientSize = dfl.all.Size(488, 324);
		//~DFL dfl.panel.Panel=mainPanel
		mainPanel = new dfl.panel.Panel();
		mainPanel.name = "mainPanel";
		mainPanel.dock = dfl.all.DockStyle.FILL;
		mainPanel.bounds = dfl.all.Rect(0, 0, 488, 324);
		mainPanel.parent = this;
		//~DFL dfl.panel.Panel=leftPane
		leftPane = new dfl.panel.Panel();
		leftPane.name = "leftPane";
		leftPane.dock = dfl.all.DockStyle.LEFT;
		leftPane.bounds = dfl.all.Rect(0, 0, 100, 324);
		leftPane.parent = mainPanel;
		//~DFL dfl.button.Button=btnNew
		btnNew = new dfl.button.Button();
		btnNew.name = "btnNew";
		btnNew.dock = dfl.all.DockStyle.BOTTOM;
		btnNew.text = "New";
		btnNew.bounds = dfl.all.Rect(0, 301, 100, 23);
		btnNew.parent = leftPane;
		//~DFL dfl.listbox.ListBox=lstItems
		lstItems = new dfl.listbox.ListBox();
		lstItems.name = "lstItems";
		lstItems.dock = dfl.all.DockStyle.FILL;
		lstItems.integralHeight = false;
		lstItems.sorted = true;
		lstItems.bounds = dfl.all.Rect(0, 0, 100, 324);
		lstItems.parent = leftPane;
		//~DFL dfl.splitter.Splitter=poppler
		poppler = new dfl.splitter.Splitter();
		poppler.name = "poppler";
		poppler.minSize = 50;
		poppler.movingGrip = false;
		poppler.bounds = dfl.all.Rect(100, 0, 6, 324);
		poppler.parent = mainPanel;
		//~DFL dfl.panel.Panel=rightPanel
		rightPanel = new dfl.panel.Panel();
		rightPanel.name = "rightPanel";
		rightPanel.dock = dfl.all.DockStyle.FILL;
		rightPanel.bounds = dfl.all.Rect(106, 0, 382, 324);
		rightPanel.parent = mainPanel;
		//~DFL dfl.textbox.TextBox=txtTitle
		txtTitle = new dfl.textbox.TextBox();
		txtTitle.name = "txtTitle";
		txtTitle.dock = dfl.all.DockStyle.TOP;
		txtTitle.bounds = dfl.all.Rect(0, 0, 382, 23);
		txtTitle.parent = rightPanel;
		//~DFL dfl.panel.Panel=panel1
		panel1 = new dfl.panel.Panel();
		panel1.name = "panel1";
		panel1.dock = dfl.all.DockStyle.TOP;
		panel1.bounds = dfl.all.Rect(0, 23, 382, 6);
		panel1.parent = rightPanel;
		//~DFL dfl.textbox.TextBox=txtContent
		txtContent = new dfl.textbox.TextBox();
		txtContent.name = "txtContent";
		txtContent.dock = dfl.all.DockStyle.FILL;
		txtContent.multiline = true;
		txtContent.acceptsReturn = true;
		txtContent.bounds = dfl.all.Rect(0, 29, 382, 295);
		txtContent.parent = rightPanel;
		//~Entice Designer 0.8.6pre4 code ends here.
	}
}


int main()
{
	int result = 0;
	
	try
	{
		Application.enableVisualStyles();
		
		//@  Other application initialization code here.
		
		Application.run(new Main());
	}
	catch(Object o)
	{
		msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
		
		result = 1;
	}
	
	return result;
}

