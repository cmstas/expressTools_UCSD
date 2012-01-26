void makeSkim(const char* ntupleI, const char* ntupleO, const char* isData, const char *skim_C, const char* libMiniFWLite_so){
  //const char* isData is a character string because it is later used as part of a string in gROOT->Macro()

  // load library to tell root how to make branches of lorentz vectors of floats if in a cmssw environment
  int loaded=gSystem->Load(libMiniFWLite_so); 
  if(loaded==0){ //check if loaded successfully
	cout<<"LibMiniFWlite \""<<libMiniFWLite_so<<"\" loaded successfully."<<endl;
  }
  else if(loaded==1){ //check if loaded successfully but has previously been loaded. I don't think it is an issue, but will include this in case it is.
	cout<<"LibMiniFWlite \""<<libMiniFWLite_so
		<<"\" loaded successfully, but libMiniFWlite has already been loaded before. This shouldn't happen, check if it is a problem."
		<<endl;
  }else if(loaded<0){ //check if it fails to load libminifwlite (for example a bad path)
	cout<<"ERROR loading LibMiniFWlite \""<<libMiniFWLite_so
		<<"\"."<<endl;
	if (gSystem->Getenv("CMSSW_BASE")) { //if it fails to load libminfwlite, see if a cmssw environment is set and load the cmssw libraries to do the same thing
	  cout<<"Found CMSSW environment. Will now attempt to load LibFWCoreFWLite."<<endl;
	  loaded=gSystem->Load("libFWCoreFWLite.so");
	  if(loaded==0){ //if cmssw libraries loaded successfully
		cout<<"LibFWCoreFWLite loaded successfully loaded."<<endl;
	  }
	  else if(loaded==1){ //if cmssw libraries loaded successfully, but have already been loaded, this shouldn't be an issue, but will check anyway
		cout<<"LibFWCoreFWLite  loaded successfully, but LibFWCoreFWLite has already been loaded before. This shouldn't happen, check if it is a problem."
			<<endl;
	  }else if(loaded<0){ //if cmssw libraries failed to be loaded
		cout<<"ERROR loading LibFWCoreFWLite."<<endl;
	  }
	  AutoLibraryLoader::enable();
	}
  }

  if(loaded<0){ //if couldn't load either library above, exit
	cout<<"ERROR.  Could not load LibMiniFWLite or LibFWCoreFWLite. Will not skim."<<endl;
	return;
  }

  TTree::SetMaxTreeSize(8000000000);
  e = new TChain("Events");
  e->Add(ntupleI);
  e->SetBranchStatus("EventAuxiliary", 0);
  if(e->GetEntries()!=0){   
	gROOT->Macro(Form("%s++(\"%s\",\"%s\",false,%s)",skim_C,ntupleI,ntupleO,isData));
  }
  else{
	cout<<"Ntuple "<<ntupleI<<" has 0 entries. Skipping skimming."<<endl;
  }  
}
