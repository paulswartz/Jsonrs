use flate2::write::{GzEncoder, ZlibEncoder};
use flate2::Compression;
use rustler::NifUnitEnum;
use std::io::{BufWriter, Error, Write};

#[derive(NifUnitEnum)]
pub enum Algs {
    None,
    Gzip,
    Zlib,
}

pub trait BufWrapper: Write {
    fn get_buf(&mut self) -> Result<Vec<u8>, Error>;
}

impl BufWrapper for Vec<u8> {
    fn get_buf(&mut self) -> Result<Vec<u8>, Error> {
        Ok(self.to_vec())
    }
}

impl BufWrapper for BufWriter<GzEncoder<Vec<u8>>> {
    fn get_buf(&mut self) -> Result<Vec<u8>, Error> {
        self.flush()?;
        self.get_mut().try_finish()?;
        Ok(self.get_ref().get_ref().to_vec())
    }
}

impl BufWrapper for BufWriter<ZlibEncoder<Vec<u8>>> {
    fn get_buf(&mut self) -> Result<Vec<u8>, Error> {
        self.flush()?;
        self.get_mut().try_finish()?;
        Ok(self.get_ref().get_ref().to_vec())
    }
}

pub fn get_writer(opts: Option<(Algs, Option<u32>)>) -> Box<dyn BufWrapper> {
    match opts {
        Some((Algs::Gzip, None)) => Box::new(BufWriter::with_capacity(
            10_240,
            GzEncoder::new(Vec::new(), Compression::default()),
        )),
        Some((Algs::Gzip, Some(lv))) => Box::new(BufWriter::with_capacity(
            10_240,
            GzEncoder::new(Vec::new(), Compression::new(lv)),
        )),
        Some((Algs::Zlib, None)) => Box::new(BufWriter::with_capacity(
            10_240,
            ZlibEncoder::new(Vec::new(), Compression::default()),
        )),
        Some((Algs::Zlib, Some(lv))) => Box::new(BufWriter::with_capacity(
            10_240,
            ZlibEncoder::new(Vec::new(), Compression::new(lv)),
        )),
        _ => Box::new(Vec::<u8>::new()),
    }
}
