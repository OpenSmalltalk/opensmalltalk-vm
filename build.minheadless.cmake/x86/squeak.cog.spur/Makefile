all:
	$(MAKE) -C debug all install
	$(MAKE) -C assert all install
	$(MAKE) -C relwithdebinfo all install
	$(MAKE) -C release all install

clean:
	$(MAKE) -C debug clean
	$(MAKE) -C assert clean
	$(MAKE) -C relwithdebinfo clean
	$(MAKE) -C release clean

distclean:
	rm -rf debug
	rm -rf assert
	rm -rf relwithdebinfo
	rm -rf release
	
