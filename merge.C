void merge(const char* nmI, const char* nmO){
 gSystem->Load("/home/users/yanjuntu/CMS2011/expressTools_UCSD_412p1_V04-00-13_Run2011A/libMiniFWLite_5.27.06b-cms10.so");


 //TTree::SetMaxTreeSize(99000000000);

	e = new TChain("Events");
 

	e->Add(nmI);

	e->Merge(nmO,"fast");
}
