void makeSkim(const char* nmI, const char* nmO, const char* expr){
  gSystem->Load("libMiniFWLite_5.27.06b-cms10.so");
  TTree::SetMaxTreeSize(39000000000ULL);
  e = new TChain("Events");
  e->Add(nmI);
  e->SetBranchStatus("EventAuxiliary", 0);
  if (e->GetEntries()!=0){
    fCp = new TFile(nmO,"recreate");
 
    chCp = e->CopyTree(expr);
    chCp->Write();
    fCp = gFile; fCp->Write();
    fCp->Close();
  }
}
